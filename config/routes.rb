require 'action_dispatch/middleware/static'
Rails.application.routes.draw do
  get '/', to: 'home#index'

  namespace :api do
    namespace :v1 do
      # /api/v1
      resources :validation_codes, only: [:create] 
      resource :session, only: [:create, :destroy]
      resource :me, only: [:show]
      resources :items do 
        collection do 
          get :balance
          get :summary
        end
      end
      resources :tags 
    end
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
end
