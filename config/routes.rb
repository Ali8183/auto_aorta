Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "listings#index"

  resources :listings do
    member do
      get :capture
      get :download_capture_zip
      post :download_capture_zip
      post :optimize
      post :publish
      post :simulate_time_lapse
    end
  end

  get "capture", to: "listings#capture_new", as: :capture
  post "capture/download_zip", to: "listings#download_capture_zip", as: :capture_download_zip

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
