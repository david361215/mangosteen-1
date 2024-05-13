Rails.application.routes.draw do
  get '/', to: 'home#index'

  namespace :api do
    namespace :v1 do
      # /api/v1
      resources :validation_codes, only: [:create] 
      resource :session, only: [:create, :destroy]
      resource :me, only: [:show]
      resources :items
      resources :tags 
    end
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
end
