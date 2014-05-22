Accounts::Application.routes.draw do

  root :to => 'static_pages#home'

  use_doorkeeper do
    controllers :applications => 'oauth/applications'
  end

  mount FinePrint::Engine => '/admin/fine_print'

  namespace 'dev' do
    resources :users, only: [:create] do
      post 'generate', on: :collection
    end
  end

  namespace 'admin' do
    get '/', to: 'base#index'

    put 'cron',                         to: 'base#cron', :as => 'cron'
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

    # resource :application_user, only: [:show, :update, :destroy]

    resources :messages, only: [:create] do
      get 'c', to: :create, on: :collection
    end
  end

  # Resources

  resources :terms, only: [:index, :show] do
    collection do
      get 'pose'
      post 'agree', as: 'agree_to'
    end
  end

  # Singular routes
  # Only for routes with unique names

  resource :session, only: [], path: '', as: '' do
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

  resource :user, only: [], path: '', as: '' do
    get 'register'
    put 'register'
  end

  resource :identity, only: [], path: '', as: '' do
    get 'signup', to: :new
    get 'forgot_password'
    post 'forgot_password'
    get 'reset_password'
    post 'reset_password'
  end

  resource :contact_info, only: [], path: '', as: '' do
    get 'confirm'
  end

  resource :static_page, only: [], path: '', as: '' do
    get 'api'
    get 'copyright'
    get 'status'
  end

end
