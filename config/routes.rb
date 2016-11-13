Rails.application.routes.draw do

  mount OpenStax::Api::Engine, at: '/'

  # More often used routes should appear first
  root to: 'static_pages#home'

  match '/auth/salesforce/callback', to: 'admin/salesforce#callback',
                                     via: [:get, :post]

  scope controller: 'sessions' do
    get 'login', action: :new

    post 'lookup_login'

    get 'authenticate'

    get 'auth/:provider/callback', action: :create
    post 'auth/:provider/callback', action: :create

    get 'logout', action: :destroy

    get 'redirect_back'

    get 'failure', path: 'auth/failure'

    get 'help', path: '/login/help', as: :login_help
    post 'help', path: '/login/help'

    # Maintain these deprecated routes for a while until client code learns to
    # use /login and /logout
    get 'signin', action: :new
    get 'signout', action: :destroy
  end

  scope controller: 'authentications' do
    delete 'auth/:provider', action: :destroy
  end

  # routes for access via an iframe
  scope 'remote', controller: 'remote' do
    get 'iframe'
    get 'notify_logout', as: 'iframe_after_logout'
  end

  scope controller: 'users' do
    get 'profile', action: :edit
    put 'profile', action: :update
  end

  namespace 'signup' do
    get '/', action: :start
    get 'password'
    get 'social'
    # post 'social'


    post 'submit_email'
    get 'verify_email'
    post 'check_pin'
    get 'check_token'
    post 'submit_password'
    get 'profile'
    post 'profile'
  end

  resource :identity, only: :update
  scope controller: 'identities' do
    get 'reset_password'
    post 'reset_password'
  end

  resources :contact_infos, only: [:create, :destroy] do
    member do
      put 'set_searchable'
      put 'resend_confirmation'
    end
  end
  scope controller: 'contact_infos' do
    get 'confirm'
    get 'confirm/unclaimed', action: :confirm_unclaimed
  end

  resources :terms, only: [:index, :show] do
    collection do
      get 'pose'
      post 'agree', as: 'agree_to'
    end
  end

  scope controller: 'static_pages' do
    get 'copyright'
    get 'status'
    get 'api'
  end

  apipie

  api :v1, default: true do
    resources :users, only: [:index]

    resource :user, only: [:show, :update] do
      post '/find-or-create', action: 'find_or_create'
    end

    resources :application_users, only: [:index] do
      collection do
        get 'find/username/:username', action: 'find_by_username'
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

    resources :contact_infos, only: [] do
      member do
        put 'resend_confirmation'
        put 'confirm_by_pin'
      end
    end

    unless Rails.env.production?
      get 'raise_exception/:type', to: 'dev#raise_exception'
    end
  end

  use_doorkeeper{ controllers applications: 'oauth/applications' }

  mount FinePrint::Engine => '/admin/fine_print'

  namespace 'admin' do
    get '/', to: 'base#index'
    get '/console', to: 'console#index'

    put 'cron',                         to: 'base#cron'
    get 'raise_exception/:type',        to: 'base#raise_exception', as: 'raise_exception'

    resources :users, only: [:index, :update, :edit] do
      post 'become', on: :member
    end

    resource :security_log, only: [:show]

    post :verify_contact_info, path: '/contact_infos/:id/verify',
         controller: :contact_infos, action: :verify

    resource :salesforce, only: [:show], controller: :salesforce do
      collection do
        delete :destroy_user
        put :update_users
      end
    end
  end

  namespace 'dev' do
    resources :users, only: [:create] do
      post 'generate', on: :collection
    end
  end

end
