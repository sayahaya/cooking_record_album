module Api
  module V1
    class CookingRecordsController < ApplicationController
      # Paginationのデフォルト値として使用される定数
      # 現在はこのコントローラーでのみ使用されるため、コントローラー内に定義しています。
      DEFAULT_LIMIT = 10.freeze
      DEFAULT_PAGE = 1.freeze

      def index
        recipe_type = params[:recipe_type]
        page = params[:page].presence || DEFAULT_PAGE
        limit = params[:limit].presence || DEFAULT_LIMIT

        begin
          result = CookingRecordService.fetch_filtered_and_paginated_records(
            recipe_type: recipe_type,
            page: page,
            limit: limit
          )

          if result[:error]
            respond_to do |format|
              format.json { render json: { error: result[:error] }, status: :service_unavailable }
              format.turbo_stream { render turbo_stream: turbo_stream.replace("cooking_records_list", partial: "api/v1/cooking_records/index", locals: { error: result[:error], records: [] }) }
              format.html { render :index, locals: { error: result[:error], records: [] } }
            end
          else
            respond_to do |format|
              format.json { render json: { records: result[:records], pagination: result[:pagination] }, status: :ok }
              format.turbo_stream { render turbo_stream: turbo_stream.replace("cooking_records_list", partial: "api/v1/cooking_records/index", locals: { error: nil, records: result[:records] }) }
              format.html { render :index, locals: { records: result[:records], error: nil } }
            end
          end
        rescue => e
          # 本来はApplicationControllerで共通の500エラーハンドリングを実装する方が望ましいと個人的に考えていますが、
          # 一旦ここで仮置きのエラーハンドリングを行っています。
          message = "エラーが発生しました。時間を置いて再度お試しください。"
          respond_to do |format|
            format.json { render json: { error: message }, status: :internal_server_error }
            format.turbo_stream { render turbo_stream: turbo_stream.replace("cooking_records_list", partial: "api/v1/cooking_records/index", locals: { error: message, records: [] }) }
            format.html { render :index, locals: { error: message, records: [] } }
          end
        end
      end
    end
  end
end
