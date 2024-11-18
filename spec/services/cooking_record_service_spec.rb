require 'rails_helper'

RSpec.describe CookingRecordService, type: :service do
  describe '#fetch_records' do
    let(:url) { 'https://cooking-records.ex.oishi-kenko.com/cooking_records' }
    subject { CookingRecordService.fetch_records }

    context '200系のレスポンスが返ってきた場合' do
      before do
        stub_request(:get, url)
          .with(query: { offset: 0, limit: 10 })
          .to_return(status: 200, body: '[{"recipe_type":"main","comment":"test"}]')
      end

      it 'JSONが正しくパースされること' do
        expect(subject).to eq([ { "recipe_type" => "main", "comment" => "test" } ])
      end
    end

    context '500系のレスポンスが返ってきた場合' do
      before do
        stub_request(:get, url)
          .with(query: { offset: 0, limit: 10 })
          .to_return(status: 500)
      end

      it 'エラーメッセージが返されること' do
        expect(subject[:error]).to eq("レコードの取得中にエラーが発生しました。時間を置いてからもう一度お試しください。")
      end
    end

    context '実行中に例外が発生した場合' do
      before do
        allow(Faraday).to receive(:new).and_raise(StandardError)
      end

      it 'エラーメッセージが返されること' do
        expect(subject[:error]).to eq("予期せぬエラーが発生しました。時間を置いてからもう一度お試しください。")
      end
    end
  end


  describe '#fetch_filtered_and_paginated_records' do
    let(:records) do
      [
        { "recipe_type" => "main", "comment" => "主菜1", "recorded_at" => "2024-01-01" },
        { "recipe_type" => "side", "comment" => "副菜1", "recorded_at" => "2024-01-02" },
        { "recipe_type" => "main", "comment" => "主菜2", "recorded_at" => "2024-01-03" }
      ]
    end

    before do
      allow(CookingRecordService).to receive(:fetch_all_records).and_return({ cooking_records: records })
    end

    context '正常系' do
      it '指定されたレシピタイプでフィルタリングされた結果を返すこと' do
        result = CookingRecordService.fetch_filtered_and_paginated_records(recipe_type: "main", page: 1, limit: 10)
        expect(result[:records].size).to eq(2)
        expect(result[:records].all? { |record| record["recipe_type"] == "main" }).to be true
      end

      it 'ページネーションが適切に機能すること' do
        result = CookingRecordService.fetch_filtered_and_paginated_records(recipe_type: "main", page: 1, limit: 1)
        expect(result[:records].size).to eq(1)
        expect(result[:pagination][:total_pages]).to eq(2)
      end

      it 'recorded_atで降順に並び替えられていること' do
        result = CookingRecordService.fetch_filtered_and_paginated_records(recipe_type: "main", page: 1, limit: 2)
        recorded_at_dates = result[:records].map { |record| record["recorded_at"] }
        expect(recorded_at_dates).to eq([ "2024-01-03", "2024-01-01" ])
      end
    end

    context '異常系' do
      before do
        allow(CookingRecordService).to receive(:fetch_all_records).and_return({ error: "レコードの取得中にエラーが発生しました。時間を置いてからもう一度お試しください。" })
      end

      it 'エラーが返された場合はエラーメッセージを含む結果を返すこと' do
        result = CookingRecordService.fetch_filtered_and_paginated_records(recipe_type: "main", page: 1, limit: 2)
        expect(result[:error]).to eq("レコードの取得中にエラーが発生しました。時間を置いてからもう一度お試しください。")
      end
    end
  end
end
