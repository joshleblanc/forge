Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # API routes
  namespace :api do
    # Authentication
    post "auth/register" => "auth#register"
    post "auth/login" => "auth#login"
    delete "auth/logout" => "auth#destroy"
    get "auth/me" => "auth#me"
    
    # Packages
    resources :packages, only: [:index, :show]
    post "packages/publish" => "packages#publish"
    get "packages/updates" => "packages#updates"
    post "packages/check_updates" => "packages#check_updates"
    get "packages/all_versions" => "packages#all_versions"
    get "packages/:id/latest" => "packages#latest"
    get "packages/:id/samples" => "packages#samples"
    get "packages/:id/samples/:sample_name" => "packages#sample"
  end

  # Package routes - publish before resources to avoid conflict
  get "/packages/publish" => "packages/publish#new"
  post "/packages/publish" => "packages/publish#create"
  resources :packages, only: [:index, :show], param: :id
  
  root "packages#index"

  # Authentication routes
  get "/login", to: "users/sessions#new", as: :login
  post "/login", to: "users/sessions#create"
  delete "/logout", to: "users/sessions#destroy", as: :logout
  get "/register", to: "users/registrations#new", as: :register
  post "/register", to: "users/registrations#create"

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
