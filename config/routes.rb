Accounts::Application.routes.draw do

  # More often used routes should appear first
  root :to => 'static_pages#home'

  scope controller: 'sessions' do
    get 'callback', path: 'auth/:provider/callback'
    post 'callback', path: 'auth/:provider/callback'
    get 'failure', path: 'auth/failure'

    get 'login', to: :new
    get 'logout', to: :destroy
    get 'i_am_returning'

    if Rails.env.development?
      get 'ask_new_or_returning'
    end
  end

  resource :user, only: [:show, :update]
  scope controller: 'users' do
    get 'register'
    put 'register'
  end

  scope controller: 'identities' do
    get 'signup', action: :new
    get 'forgot_password'
    post 'forgot_password'
    get 'reset_password'
    post 'reset_password'
  end

  resources :terms, only: [:index, :show] do
    collection do
      get 'pose'
      post 'agree', as: 'agree_to'
    end
  end

  scope controller: 'contact_infos' do
    get 'confirm'
  end

  scope controller: 'static_pages' do
    get 'api'
    get 'copyright'
    get 'status'
  end

  apipie

  api :v1, :default => true do
    resources :users, only: [:index]

    resource :user, only: [:show, :update]

    resources :contact_infos, only: [:show, :create, :destroy] do
      put 'resend_confirmation', on: :member
    end

    resources :application_users, only: [:index] do
      collection do
        get 'updates'
        put 'updated'
      end
    end

    resources :application_groups, only: [] do
      collection do
        get 'updates'
        put 'updated'
      end
    end

    resources :messages, only: [:create]

    resources :groups, only: [:index, :show, :create, :update, :destroy] do
      post '/members/:user_id', to: 'group_members#create'
      delete '/members/:user_id', to: 'group_members#destroy'

      post '/owners/:user_id', to: 'group_owners#create'
      delete '/owners/:user_id', to: 'group_owners#destroy'

      post '/nestings/:member_group_id', to: 'group_nestings#create'
      delete '/nestings/:member_group_id', to: 'group_nestings#destroy'
    end

    resources :group_members, only: [:index], path: 'memberships'
    resources :group_owners, only: [:index], path: 'ownerships'
  end

  use_doorkeeper do
    controllers :applications => 'oauth/applications'
  end

  mount FinePrint::Engine => '/admin/fine_print'

  namespace 'admin' do
    get '/', to: 'base#index'

    put 'cron',                         to: 'base#cron'
    get 'raise_security_transgression', to: 'base#raise_security_transgression'
    get 'raise_record_not_found',       to: 'base#raise_record_not_found'
    get 'raise_routing_error',          to: 'base#raise_routing_error'
    get 'raise_unknown_controller',     to: 'base#raise_unknown_controller'
    get 'raise_unknown_action',         to: 'base#raise_unknown_action'
    get 'raise_missing_template',       to: 'base#raise_missing_template'
    get 'raise_not_yet_implemented',    to: 'base#raise_not_yet_implemented'
    get 'raise_illegal_argument',       to: 'base#raise_illegal_argument'

    resources :users, only: [:index, :show, :update, :edit] do
      post 'become', on: :member
    end
  end

  namespace 'dev' do
    resources :users, only: [:create] do
      post 'generate', on: :collection
    end
  end

end
