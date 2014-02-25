Services::Application.routes.draw do
  
  use_doorkeeper

  apipie

  namespace :api, defaults: {format: 'json'} do
    scope module: :v1, constraints: ApiConstraints.new(version: 1) do
      get '/me' => 'credentials#me'

      resources :users, only: [:show]
    end
  end

  get "do/confirm_email"
  
  match '/auth/:provider/callback', to: 'sessions#authenticated' #omniauth route
  match '/signup', to: 'identities#new'
  
  match '/login', to: 'sessions#new'
  match "/auth/failure", to: "sessions#failure"
  match '/logout', to: 'sessions#destroy'

  
  get 'sessions/return_to_app'
  match '/i_am_returning', to: 'sessions#i_am_returning'

  get 'api', to: 'static_page#api'
  match 'copyright', :to => 'static_page#copyright'

  root :to => "static_page#home"

  if Rails.env.development?
    get 'sessions/ask_new_or_returning'
  end  
end
