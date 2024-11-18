class CookingRecordService
  # TODO: 汎用的に使う用途がありそうであれば、lib配下にAPIクライアントを移設も検討する
  BASE_URL = "https://cooking-records.ex.oishi-kenko.com".freeze

  # レコードを取得する
  #
  # @param  [Integer] offset 取得開始位置のオフセット
  # @param  [Integer] limit  取得するレコードの上限数
  # @return [Hash]   取得結果またはエラーメッセージを含むハッシュ
  def self.fetch_records(offset: 0, limit: 10)
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
end
