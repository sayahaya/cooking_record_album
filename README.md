# 料理記録アルバム

## プロジェクト概要
「料理記録アルバム」は、料理の記録を簡単に管理し、画像付きで保存できるRailsアプリケーションです。料理の種類別にレシピを整理し、一覧表示、レシピ種別ごとの検索機能、ページネーションなどの機能を提供します。

## セットアップガイド
### 依存関係のインストール
```
bundle install
yarn install
```

### アプリケーションの起動
```
rails server
```

### ライブラリとバージョン情報（自身で追加したもののみを抜粋）
- Ruby: 3.3.5
- Rails: 7.2.1.1
- Faraday: 2.12.0
- Bootstrap: 5.3.3
  ※下記gemはBootstrapを導入にあたり付随で追加
  - jquery-rails 4.6.0
  - sassc-rails 2.1.2
- Kaminari: 1.2.2
- bootstrap5-kaminari-views: 0.0.1
- rspec-rails: 7.0.1
- webmock: 3.24.0

### アクセス方法
アプリのルートURLは、起動後にブラウザで以下のエンドポイントにアクセスしてください：

URL: http://localhost:3000/cooking_records
（もしくはroot_urlに設定されているため、アプリを起動後そのままアクセスできます）

※デフォルトのポート番号3000番を使う想定ですが、必要があれば適宜config/puma.rbの下記を変更するか、
```
port ENV.fetch("PORT") { ポート番号 }
```
サーバー起動時にポート番号を指定してください
```
rails server -p <ポート番号>
```

### テストの実行
RSpecを使用してテストを実行します。
```
bundle exec rspec
```
