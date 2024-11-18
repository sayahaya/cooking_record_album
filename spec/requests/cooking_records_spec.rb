require 'rails_helper'

RSpec.describe "CookingRecords", type: :request do
  describe "index" do
    let!(:records) { Array.new(15) { |i| { 'recipe_type' => 'main', 'comment' => "テスト #{i + 1}" } } }

    before do
      allow(CookingRecordService).to receive(:fetch_records).and_return(
        { 'cooking_records' => records[0..9] },
        { 'cooking_records' => records[10..14] },
        { 'cooking_records' => [] }
      )
    end

    context '正常系' do
      it 'ステータス200を返すこと' do
        get cooking_records_path
        expect(response).to have_http_status(:ok)
      end

      it '指定した件数のレコードが取得されること' do
        get cooking_records_path
        # デフォルトのlimitに合わせて10件のみ取得される
        expect(controller.instance_variable_get(:@records).count).to eq(10)
      end

      context 'レシピタイプでのフィルタリングをした場合' do
        it 'フィルタリングされた結果が返されること' do
          allow(CookingRecordService).to receive(:fetch_records).and_return({ records: records.select { |r| r['recipe_type'] == 'main' } })
          get cooking_records_path, params: { recipe_type: 'main' }
          expect(controller.instance_variable_get(:@records).all? { |r| r['recipe_type'] == 'main' }).to be true
        end
      end

      context 'recorded_at順での並び替え' do
        let!(:records) do
          [
            { 'recipe_type' => 'main', 'comment' => '古い記録', 'recorded_at' => '2023-01-01 00:00:00' },
            { 'recipe_type' => 'main', 'comment' => '新しい記録', 'recorded_at' => '2024-01-01 00:00:00' }
          ]
        end

        before do
          allow(CookingRecordService).to receive(:fetch_records).and_return(
            { 'cooking_records' => records[0..1] },
            { 'cooking_records' => [] }
          )
        end

        it 'recorded_atが降順で並び替えられていること' do
          get cooking_records_path
          sorted_records = controller.instance_variable_get(:@records)
          expect(sorted_records.first['comment']).to eq('新しい記録')
          expect(sorted_records.last['comment']).to eq('古い記録')
        end
      end
    end

    context '異常系' do
      context 'APIからのエラーレスポンスが返ってきた場合' do
        before do
          allow(CookingRecordService).to receive(:fetch_records).and_return({ error: "レコードの取得中にエラーが発生しました。時間を置いてからもう一度お試しください。" })
        end

        it 'エラーメッセージが設定され、空のレコードが返されること' do
          get cooking_records_path
          expect(controller.instance_variable_get(:@error)).to eq("レコードの取得中にエラーが発生しました。時間を置いてからもう一度お試しください。")
          expect(controller.instance_variable_get(:@records)).to eq([])
        end
      end

      context '予期しないシステムエラーが発生した場合' do
        before do
          allow(CookingRecordService).to receive(:fetch_records).and_raise(StandardError)
        end

        it '500エラー用のメッセージが設定され、空のレコードが返されること' do
          get cooking_records_path
          expect(controller.instance_variable_get(:@error)).to eq("システムエラーが発生しました。時間をおいて再度お試しください。")
          expect(controller.instance_variable_get(:@records)).to eq([])
        end
      end
    end
  end
end
