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
end
