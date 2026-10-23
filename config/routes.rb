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

  # Embeddable 360° Spin Widget for external websites / portals
  namespace :embed do
    resources :listings, only: [ :show ]
  end

  # Agent-First REST API for external AI bots, dealership CRMs & automated inventory engines
  namespace :api do
    namespace :v1 do
      resources :merchandise, controller: "merchandising", only: [ :create, :show ]
    end
  end
end
