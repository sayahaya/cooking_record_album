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
      # 全件データを取得
      response = fetch_all_records

      if response[:error]
        @error = response[:error]
        @records = []
      else
        # レシピの種類の絞り込みに合わせたレコードを取得
        filtered_records = filter_records(response[:records], recipe_type)
        # recorded_atを降順で並べたレコードをページネーションで返す
        @records = Kaminari.paginate_array(order_by_recorded_at_desc(filtered_records)).page(page).per(limit)
      end
    rescue => e
      # 本来はApplicationControllerで共通の500エラーハンドリングを実装する方が望ましいと個人的に考えていますが、
      # 一旦ここで仮置きのエラーハンドリングを行っています。
      @error = "システムエラーが発生しました。時間をおいて再度お試しください。"
      @records = []
    end
  end

  private

  # 全件取得を行う
  #
  # @return [Hash] 全件のレコードまたはエラーメッセージを含むハッシュ
  def fetch_all_records
    all_records = []
    offset = 0
    # 一旦100件毎にループ処理を実行するようにする
    limit = 100

    loop do
      response = CookingRecordService.fetch_records(offset: offset, limit: limit)

      # エラーレスポンスがある場合は処理を終了
      return { error: response[:error] } if response[:error]
      break if response["cooking_records"].blank?

      all_records.concat(response["cooking_records"])
      offset += limit
    end

    { records: all_records }
  end

  # レシピの種類でレコードを絞り込む
  #
  # @param [Array<Hash>] records レコード一覧
  # @param [String] recipe_type 絞り込み対象のレシピの種類
  # @return [Array<Hash>] 絞り込み結果のレコード一覧
  def filter_records(records, recipe_type)
    return records if recipe_type.blank?

    records.select { |record| record["recipe_type"] == recipe_type }
  end

  # recorded_atカラムを基準に降順で並び替える
  #
  # @param [Array<Hash>] records レコード一覧
  # @return [Array<Hash>] recorded_at降順に並び替えられたレコード一覧
  def order_by_recorded_at_desc(records)
    records.sort_by { |record| record["recorded_at"] }.reverse
  end
end
