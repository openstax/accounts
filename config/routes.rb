Accounts::Application.routes.draw do

  use_doorkeeper do
    controllers :applications => 'oauth/applications'
  end

  mount FinePrint::Engine => "/admin/fine_print"

  namespace 'dev' do
    namespace 'users' do
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

    resources :users, only: [:index, :show, :update, :edit]
  end

  apipie

  get 'api', to: 'static_page#api'

  api :v1, :default => true do
    resource :user, only: [:show, :update]

    resources :contact_infos, only: [:show, :create, :destroy] do
      put 'resend_confirmation', on: :member
    end

    resources :application_users, only: [:index, :create] do
      collection do
        get 'updates'
        put 'updated'
      end
    end
  end

  get "do/confirm_email"

  match '/auth/:provider/callback', to: 'sessions#authenticated' #omniauth route
  match '/signup', to: 'identities#new'
  
  match '/login', to: 'sessions#new'
  match "/auth/failure", to: "sessions#failure"
  match '/logout', to: 'sessions#destroy'
  match '/forgot_password', to: 'identities#forgot_password'
  match '/reset_password', to: 'identities#reset_password'


  get 'sessions/return_to_app'
  match '/i_am_returning', to: 'sessions#i_am_returning'

  match 'users/register', to: 'users#register'
  post 'users/:id/become', to: 'users#become', as: 'become_user'

  get "terms/:id/show", to: "terms#show", as: "show_terms"
  get "terms/pose", to: "terms#pose", as: "pose_terms"
  post "terms/agree", to: "terms#agree", as: "agree_to_terms"
  get "terms", to: "terms#index"

  get 'status', to: 'utility#status'

  match 'copyright', :to => 'static_page#copyright'

  root :to => "static_page#home"

  if Rails.env.development?
    get 'sessions/ask_new_or_returning'
  end  
end
