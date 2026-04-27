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
    post "auth/verify" => "auth#verify"

    # Packages
    resources :packages, only: [:index, :show]
    post "packages/publish" => "packages#publish"
    get "packages/updates" => "packages#updates"
    post "packages/check_updates" => "packages#check_updates"
    get "packages/all_versions" => "packages#all_versions"
    get "packages/:id/latest" => "packages#latest"
    get "packages/:id/samples" => "packages#samples"
    get "packages/:id/samples/:sample_name" => "packages#sample"
    get "packages/:id/versions/:version/download", to: "packages#download", constraints: { version: /[^\/]+/ }
    get "packages/:id/versions/:version/files", to: "packages#files", constraints: { version: /[^\/]+/ }
    get "packages/:id/versions/:version/files/*path", to: "packages#file", constraints: { version: /[^\/]+/ }
    get "packages/:id/versions/:version", to: "packages#version_info", constraints: { version: /[^\/]+/ }
    post "packages/:id/versions/:version/upload", to: "packages#upload", constraints: { version: /[^\/]+/ }
    delete "packages/:id/versions/:version/file", to: "packages#delete_file", constraints: { version: /[^\/]+/ }
    get "packages/:id/storage_info" => "packages#storage_info"
  end

  # Package routes - publish before resources to avoid conflict
  get "/packages/publish" => "packages/publish#new"
  post "/packages/publish" => "packages/publish#create"
  resources :packages, only: [:index, :show], param: :id

  # File browser (Turbo Frame partials — version passed as query param from show page)
  get "packages/:id/files", to: "packages#file_tree", as: :package_files
  get "packages/:id/files/*path", to: "packages#file_content", as: :package_file_content, constraints: { path: %r{.+} }

  # Forge new project download
  get "/new" => "forge#new"
  get "/new/download" => "forge#download"

  root "packages#index"

  # Authentication routes
  get "/login", to: "users/sessions#new", as: :login
  post "/login", to: "users/sessions#create"
  delete "/logout", to: "users/sessions#destroy", as: :logout
  get "/register", to: "users/registrations#new", as: :register
  post "/register", to: "users/registrations#create"

  # User settings & API key management
  get "/settings", to: "users/settings#show", as: :settings
  patch "/settings", to: "users/settings#update"
  post "/settings/claim_key", to: "users/settings#claim_key", as: :claim_key
  post "/settings/create_key", to: "users/settings#create_key", as: :create_key
  delete "/settings/destroy_key/:id", to: "users/settings#destroy_key", as: :destroy_key
  post "/settings/regenerate_key/:id", to: "users/settings#regenerate_key", as: :regenerate_key

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
