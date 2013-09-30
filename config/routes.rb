Services::Application.routes.draw do
  
  use_doorkeeper

  apipie

  namespace :api do
    namespace :v1 do
      get '/me' => 'credentials#me'
    end
  end

  get "do/confirm_email"
  
  match '/auth/:provider/callback', to: 'sessions#authenticated' #omniauth route
  match '/signup', to: 'identities#new'
  
  match '/login', to: 'sessions#new'
  match "/auth/failure", to: "sessions#failure"
  match '/logout', to: 'sessions#destroy'

  
  get 'sessions/register'
  put 'sessions/finish_registration'
  match '/i_am_returning', to: 'sessions#i_am_returning'

  match 'copyright', :to => 'static_page#copyright'

  root :to => "static_page#home"

  if Rails.env.development?
    get 'sessions/ask_new_or_returning'
  end  
end
