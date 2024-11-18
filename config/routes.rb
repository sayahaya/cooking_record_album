Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :cooking_records, only: [ :index ]
    end
  end

  # ブラウザでの確認用にデフォルトのルートを設定
  root "api/v1/cooking_records#index"
end
