Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root to: 'static_pages#home'

  mount OpenStax::Salesforce::Engine, at: '/admin/salesforce'
  OpenStax::Salesforce.set_top_level_routes(self)

  scope controller: 'newflow' do
    get 'i/login_raw', action: :login_raw
    get 'i/login', action: :login, as: :newflow_login
    post 'i/login', action: :newflow_login_post
    get 'i/login_failed', action: :login_failed, as: :newflow_login_failed

    get 'i/signup_raw', action: :signup_raw
    get 'i/signup', action: :signup, as: :newflow_signup

    get 'i/welcome', action: :welcome, as: :newflow_welcome
    get 'i/confirm', action: :confirm
    get 'i/done', action: :done

    get 'i/auth/:provider', action: :newflow_login_callback, as: :newflow_auth
    post 'i/auth/:provider', action: :newflow_login_callback

    get 'i/auth/:provider/callback', action: :newflow_login_callback
    post 'i/auth/:provider/callback', action: :newflow_login_callback, as: :newflow_callback

    get 'i/profile', action: :profile_newflow, as: :profile_newflow
    get 'i/newflow_logout', action: :logout, as: :newflow_logout
  end

  scope controller: 'sessions' do
    get 'login', action: :start, as: :login

    post 'lookup_login'

    get 'authenticate'

    get 'reauthenticate'

    get 'auth/:provider/callback', action: :create, as: :get_auth_callback
    post 'auth/:provider/callback', action: :create, as: :post_auth_callback

    get 'logout', action: :destroy

    get 'redirect_back'

    get :failure, path: 'auth/failure', as: :auth_failure
    post 'email_usernames'

    # Maintain these deprecated routes for a while until client code learns to
    # use /login and /logout
    get 'signin', action: :start
    get 'signout', action: :destroy
  end

  mount OpenStax::Api::Engine, at: '/'

  # Create a named path for links like `/auth/facebook` so that the path prefixer gem
  #     will appropriately prefix the path. https://stackoverflow.com/a/40125738/1664216
  # The actual request, however, is handled by the omniauth middleware when it detects
  #     that the current_url is the callback_path, using `OmniAuth::Strategy#on_callback_path?`
  #     So, admittedly, this route is deceiving.
  get "/auth/:provider", to: lambda{ |env| [404, {}, ["Not Found"]] }, as: :oauth

  scope controller: 'authentications' do
    delete 'auth/:provider', action: :destroy, as: :destroy_authentication
    get 'add/:provider', action: :add, as: :add_authentication
  end

  scope controller: 'signup' do
    # Don't know if this is the right action; putting a route in here
    # so we have a name for it and can use a url helper for it (which
    # will prefix the route appropriately, e.g. for Cloudfront)
    post 'auth/:provider/signup', action: :start, as: :post_auth_signup
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
    post '/', action: :start
    get 'password'
    get 'social'

    get 'verify_email'
    post 'verify_email'

    get 'verify_by_token'

    get 'profile'
    post 'profile'

    match 'instructor_access_pending', via: [:get, :post]
  end

  scope controller: 'identities', path: 'password', as: 'password' do
    get 'reset'
    post 'reset'

    post 'send_reset'
    get 'sent_reset'

    post 'send_add'
    get 'sent_add'

    get 'add'
    post 'add'

    get 'reset_success'
    get 'add_success'

    get 'continue'
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

  namespace 'faculty_access' do
    match 'apply', via: [:get, :post]
    match 'pending', via: [:get, :post]
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

  use_doorkeeper { controllers applications: 'oauth/applications' }

  mount FinePrint::Engine => '/admin/fine_print'

  namespace 'admin' do
    get '/', to: 'base#index'
    get '/console', to: 'console#index'

    put 'cron',                         to: 'base#cron'
    get 'raise_exception/:type',        to: 'base#raise_exception', as: 'raise_exception'

    resources :users, only: [:index, :update, :edit] do
      post 'become', on: :member
      get 'search', on: :collection
      get 'js_search', on: :collection
      get 'actions', on: :collection
      put 'mark_users_updated', on: :collection
    end

    resource :reports, only: [:show]

    resource :security_log, only: [:show]

    delete :delete_contact_info, path: '/contact_infos/:id/verify',
         controller: :contact_infos, action: :destroy
    post :verify_contact_info, path: '/contact_infos/:id/verify',
         controller: :contact_infos, action: :verify

    resource :salesforce, only: [], controller: :salesforce do
      collection do
        get :actions
        put :update_users
      end
    end

    resources :pre_auth_states, only: [:index]

    resources :banners, except: :show

    mount RailsSettingsUi::Engine, at: 'settings'
  end

  namespace 'dev' do
    resources :users, only: [:create] do
      post 'generate', on: :collection
    end
  end

  if Rails.env.test?
    get '/external_app_for_specs' => 'external_app_for_specs#index'
  end
end
