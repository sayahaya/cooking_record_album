require 'rails_helper'

RSpec.describe "Api::V1::CookingRecords", type: :system do
  before do
    # JavaScriptのテストがないので一旦軽量なrack_testを採用
    # TODO:今後他のsystemスペックが増えたときには、個別specファイルでドライバを設定せず、spec_helper.rbで設定する
    driven_by(:rack_test)
    stub_request(:get, "https://cooking-records.ex.oishi-kenko.com/cooking_records")
      .with(query: { limit: 100, offset: 0 })
      .to_return(status: 200, body: '{"cooking_records": []}', headers: {})
  end

  describe '料理記録アルバム' do
    before do
      visit api_v1_cooking_records_path
    end

    context 'ページが正しく表示される場合' do
      it 'フォームが表示されること' do
        expect(page).to have_selector("form")
        expect(page).to have_selector("select[name='recipe_type']")
      end

      it '絞り込みフォームが機能すること' do
        select '主菜', from: 'recipe_type'
        click_button '絞り込む'
        expect(page).to have_content '主菜'
      end
    end

    context 'レコードがある場合' do
      before do
        records = Array.new(15) { |i| { 'recipe_type' => 'main', 'comment' => "Comment #{i + 1}" } }
        allow(CookingRecordService).to receive(:fetch_records).and_return(
          { 'cooking_records' => records[0..9] },
          { 'cooking_records' => records[10..14] },
          { 'cooking_records' => [] }
        )
      end

      it 'レコードが表示され、次へボタンが存在すること' do
        visit api_v1_cooking_records_path
        expect(page).to have_selector(".record-list .col-md-4", count: 10)
        expect(page).to have_selector('a[rel="next"]', text: '次')
      end
    end

    context 'エラーメッセージがある場合' do
      it 'エラーメッセージが表示されること' do
        allow(CookingRecordService).to receive(:fetch_records).and_return({ error: 'エラーが発生しました' })
        visit api_v1_cooking_records_path
        expect(page).to have_content 'エラーが発生しました'
      end
    end

    context 'レコードがない場合' do
      before do
        allow(CookingRecordService).to receive(:fetch_records).and_return({ 'cooking_records' => [] })
      end

      it '「表示するレシピがありません」が表示されること' do
        visit api_v1_cooking_records_path
        expect(page).to have_content '表示するレシピがありません'
      end
    end
  end
end
