Accounts::Application.routes.draw do
  
  use_doorkeeper

  apipie

  namespace 'dev' do
    get "/", to: 'base#index'

    namespace 'users' do
      post 'search'
      post 'create'
      post 'generate'
    end
  end

  namespace 'admin' do
    get '/', to: 'base#index'

    put "cron",                         to: 'base#cron', :as => "cron"
    get "raise_security_transgression", to: 'base#raise_security_transgression'
    get "raise_record_not_found",       to: 'base#raise_record_not_found'
    get "raise_routing_error",          to: 'base#raise_routing_error'
    get "raise_unknown_controller",     to: 'base#raise_unknown_controller'
    get "raise_unknown_action",         to: 'base#raise_unknown_action'
    get "raise_missing_template",       to: 'base#raise_missing_template'
    get "raise_not_yet_implemented",    to: 'base#raise_not_yet_implemented'
    get "raise_illegal_argument",       to: 'base#raise_illegal_argument'

    resources :users, only: [:show, :update, :edit] do
      post 'search', on: :collection
    end
  end

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
