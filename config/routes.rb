require 'sidekiq/web'
Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
  mount Notifications::Engine => "/notifications"
  resource :signup, only: %i[create]
  resources :authentications, only: %i[create]
  resources :users, only: %i[index] do
    collection do
      get 'deleted_list'
      get 'track_logs'
    end
  end
  post 'users/archive'
  mount Sidekiq::Web => '/sidekiq'
end
