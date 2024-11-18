class CookingRecordService
  class << self
    # TODO: 汎用的に使う用途がありそうであれば、lib配下にAPIクライアントを移設も検討する
    BASE_URL = "https://cooking-records.ex.oishi-kenko.com".freeze

    # レコードを取得する
    #
    # @param  [Integer] offset 取得開始位置のオフセット
    # @param  [Integer] limit  取得するレコードの上限数
    # @return [Hash]   取得結果またはエラーメッセージを含むハッシュ
    def fetch_records(offset: 0, limit: 10)
      # APIの仕様上、offsetとlimitを設定しないとoffset: 0、limit: 10のレスポンスが返る
      # 上記のAPIの仕様を呼び出し側が明示的に分かりやすいようにデフォルト引数にoffsetとlimitを設定している
      connection = Faraday.new(url: BASE_URL)

      response = connection.get("/cooking_records", { offset: offset, limit: limit })

      # 200系のステータスは一旦成功とする
      if response.success?
        JSON.parse(response.body)
      else
        # TODO: エラーハンドリングのパターン、エラーメッセージは後ほどチームで詳細詰める
        { error: "レコードの取得中にエラーが発生しました。時間を置いてからもう一度お試しください。" }
      end
    rescue => e
      { error: "予期せぬエラーが発生しました。時間を置いてからもう一度お試しください。" }
    end

    # 指定されたレシピタイプ、ページ番号、表示件数に基づいてレコードをフィルタリングし、
    # ページネーションを適用した結果を取得する
    #
    # @param recipe_type [String, nil] 絞り込むレシピタイプ（例: "main_dish", "side_dish"）
    #   nil または空文字の場合、すべてのレコードを対象とします。
    # @param page [Integer] ページネーションの現在のページ番号
    # @param limit [Integer] 取得するレコードの上限数
    # @return [Hash] フィルタリングおよびページネーションされた結果のハッシュ
    def fetch_filtered_and_paginated_records(recipe_type:, page:, limit:)
      # 全件データを取得
      response = fetch_all_records

      # エラーがある場合はそのまま返す
      return { error: response[:error] } if response[:error]

      # レシピの種類の絞り込みに合わせたレコードを取得
      filtered_records = filter_records(response[:cooking_records], recipe_type)

      # recorded_atを降順で並べたレコードをページネーションで返す
      paginated_records = Kaminari.paginate_array(order_by_recorded_at_desc(filtered_records)).page(page).per(limit)

      {
        records: paginated_records,
        pagination: {
          current_page: paginated_records.current_page,
          total_pages: paginated_records.total_pages,
          total_count: paginated_records.total_count
        }
      }
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

      { cooking_records: all_records }
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
end
