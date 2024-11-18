module Api
  module V1
    class CookingRecordsController < ApplicationController
      # Paginationのデフォルト値として使用される定数
      # 現在はこのコントローラーでのみ使用されるため、コントローラー内に定義しています。
      # TODO:将来的に他のコントローラーでも共通のページネーションロジックを使う場合は、
      #      ヘルパーモジュールやサービスクラスに切り出して再利用できるようにすることを検討する。
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
              format.html { render :index, locals: { error: result[:error], records: [] } }
            end
          else
            respond_to do |format|
              format.json { render json: { records: result[:records], pagination: result[:pagination] }, status: :ok }
              format.html { render :index, locals: { records: result[:records], error: nil } }
            end
          end
        rescue => e
          # 本来はApplicationControllerで共通の500エラーハンドリングを実装する方が望ましいと個人的に考えていますが、
          # 一旦ここで仮置きのエラーハンドリングを行っています。
          message = "エラーが発生しました。時間を置いて再度お試しください。"
          respond_to do |format|
            format.json { render json: { error: message }, status: :internal_server_error }
            format.html { render :index, locals: { error: message, records: [] } }
          end
        end
      end
    end
  end
end
