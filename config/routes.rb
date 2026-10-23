Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "listings#index"

  resources :listings do
    member do
      post :optimize
      post :publish
      post :simulate_time_lapse
    end
  end
end
