Rails.application.routes.draw do
  resources :cooking_records, only: [ :index ]
  root "cooking_records#index"
end
