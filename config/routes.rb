Accounts::Application.routes.draw do

  # More often used routes should appear first
  root :to => 'static_pages#home'

  scope controller: 'sessions' do
    get 'callback', path: 'auth/:provider/callback'
    post 'callback', path: 'auth/:provider/callback'
    get 'failure', path: 'auth/failure'

    get 'login', action: :new
    get 'logout', action: :destroy
    get 'i_am_returning'
    get 'returning_user'

    if Rails.env.development?
      get 'ask_new_or_returning'
    end
  end

  # routes for access via an iframe
  scope 'remote', controller: 'remote' do
    get 'iframe'
    get 'notify_logout', as: 'iframe_after_logout'
  end

  scope controller: 'users' do
    get 'profile', action: :edit
    put 'profile', action: :update
    get 'ask_for_email'
    put 'ask_for_email'
  end

  namespace 'registration' do
    get 'complete'
    put 'complete'
    get 'verification_pending'
    put 'i_verified'
  end

  namespace 'signup' do
    get 'password'
    get 'social'
    post 'social'
  end

  resource :identity, only: :update
  scope controller: 'identities' do
    get 'signup', action: :new
    get 'forgot_password'
    post 'forgot_password'
    get 'reset_password'
    post 'reset_password'
  end

  resources :contact_infos, only: [:create, :destroy] do
    member do
      put 'toggle_is_searchable'
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
  end

  apipie

  api :v1, :default => true do
    resources :users, only: [:index]

    resource :user, only: [:show, :update] do
      post '/find-or-create',    action: 'find_or_create'
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

    if !Rails.env.production?
      get 'raise_exception/:type', to: 'dev#raise_exception'
    end
  end

  use_doorkeeper do
    controllers :applications => 'oauth/applications'
  end

  mount FinePrint::Engine => '/admin/fine_print'

  namespace 'admin' do
    get '/', to: 'base#index'

    put 'cron',                         to: 'base#cron'
    get 'raise_exception/:type',        to: 'base#raise_exception', as: 'raise_exception'

    resources :users, only: [:index, :show, :update, :edit] do
      post 'become', on: :member
      post 'make_admin', on: :member
    end

    post :verify_contact_info, path: '/contact_infos/:id/verify',
         controller: :contact_infos, action: :verify
  end

  namespace 'dev' do
    resources :users, only: [:create] do
      post 'generate', on: :collection
    end
  end

  # Any other routes are handled here
  match '*path', to: 'application#routing_error'

end
