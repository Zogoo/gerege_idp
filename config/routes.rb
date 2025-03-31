Rails.application.routes.draw do
  # Defines the root path route ("/")
  root "home#show"

  # Devise routes
  devise_for :users, controllers: {
    sessions: "users/sessions",
    registrations: "users/registrations",
    confirmations: "users/confirmations",
    passwords: "users/passwords",
    unlocks: "users/unlocks"
  }

  namespace :api do
    namespace :v1 do
      resources :users
    end
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  mount SamlIdpRails::Engine, at: "/saml_idp" # if you want to use the SAML IdP

  namespace :users do
    get "my_page", to: "my_page#show"
  end
end
