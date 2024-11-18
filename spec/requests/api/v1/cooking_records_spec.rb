require 'rails_helper'

RSpec.describe "Api::V1::CookingRecords", type: :request do
  describe "GET /api/v1/cooking_records" do
    let!(:records) { Array.new(15) { |i| { 'recipe_type' => 'main', 'comment' => "テスト #{i + 1}" } } }

    before do
      allow(CookingRecordService).to receive(:fetch_records).and_return(
        { 'cooking_records' => records[0..9] },
        { 'cooking_records' => records[10..14] },
        { 'cooking_records' => [] }
      )
    end

    context "正常系" do
      it "ステータス200を返すこと" do
        get api_v1_cooking_records_path, headers: { "Accept" => "application/json" }
        expect(response).to have_http_status(:ok)
      end

      it "JSON形式でデータを返すこと" do
        get api_v1_cooking_records_path, headers: { "Accept" => "application/json" }
        expect(response.content_type).to eq("application/json; charset=utf-8")
      end

      it "指定した件数のレコードが取得されること" do
        get api_v1_cooking_records_path, headers: { "Accept" => "application/json" }
        json_response = JSON.parse(response.body)
        expect(json_response["records"].size).to eq(10)
      end

      context "レシピタイプでのフィルタリングをした場合" do
        it "フィルタリングされた結果が返されること" do
          filtered_records = records.select { |r| r['recipe_type'] == 'main' }
          allow(CookingRecordService).to receive(:fetch_filtered_and_paginated_records).and_return(
            { records: filtered_records, pagination: { current_page: 1, total_pages: 1, total_count: filtered_records.size } }
          )

          get api_v1_cooking_records_path, headers: { "Accept" => "application/json" }, params: { recipe_type: 'main' }
          json_response = JSON.parse(response.body)
          expect(json_response["records"].all? { |r| r["recipe_type"] == "main" }).to be true
        end
      end

      context "recorded_at順での並び替え" do
        let!(:records) do
          [
            { 'recipe_type' => 'main', 'comment' => '古い記録', 'recorded_at' => '2023-01-01 00:00:00' },
            { 'recipe_type' => 'main', 'comment' => '新しい記録', 'recorded_at' => '2024-01-01 00:00:00' }
          ]
        end

        it "recorded_atが降順で並び替えられていること" do
          allow(CookingRecordService).to receive(:fetch_filtered_and_paginated_records).and_return(
            { records: records.sort_by { |r| r["recorded_at"] }.reverse, pagination: { current_page: 1, total_pages: 1, total_count: records.size } }
          )

          get api_v1_cooking_records_path, headers: { "Accept" => "application/json" }
          json_response = JSON.parse(response.body)
          expect(json_response["records"].first["comment"]).to eq("新しい記録")
          expect(json_response["records"].last["comment"]).to eq("古い記録")
        end
      end
    end

    context "異常系" do
      context "APIからのエラーレスポンスが返ってきた場合" do
        before do
          allow(CookingRecordService).to receive(:fetch_filtered_and_paginated_records).and_return(
            { error: "レコードの取得中にエラーが発生しました。時間を置いてからもう一度お試しください。" }
          )
        end

        it "エラーメッセージが含まれるJSONを返すこと" do
          get api_v1_cooking_records_path, headers: { "Accept" => "application/json" }
          json_response = JSON.parse(response.body)
          expect(response).to have_http_status(:service_unavailable)
          expect(json_response["error"]).to eq("レコードの取得中にエラーが発生しました。時間を置いてからもう一度お試しください。")
        end
      end

      context "予期しないシステムエラーが発生した場合" do
        before do
          allow(CookingRecordService).to receive(:fetch_filtered_and_paginated_records).and_raise(StandardError)
        end

        it "500エラー用のメッセージが含まれるJSONを返すこと" do
          get api_v1_cooking_records_path, headers: { "Accept" => "application/json" }
          json_response = JSON.parse(response.body)
          expect(response).to have_http_status(:internal_server_error)
          expect(json_response["error"]).to eq("エラーが発生しました。時間を置いて再度お試しください。")
        end
      end
    end
  end
end
