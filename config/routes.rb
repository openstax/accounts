# rubocop:disable Metrics/BlockLength
Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root to: 'sessions#login_form'

  get 'i/(*path)' => redirect { |_, request|
    "/accounts/#{request.params[:path]}?#{request.params.except('path').to_query}"
  }

  # special redirects for the refactor - make sure legacy routes still route to an expected place
  get 'faculty_access/apply/' => redirect('signup/educator/apply')
  get 'faculty_access/pending/' => redirect('signup/educator/pending_cs_verification')
  get 'exit_accounts' => redirect('logout')

  direct :salesforce_knowledge_base do
    'https://openstax.secure.force.com/help/articles/FAQ/Can-t-log-in-to-your-OpenStax-account'
  end

  scope controller: :profile do
    get 'profile', action: :profile, as: :profile
    put 'profile', action: :update, as: :update_profile
  end

  scope controller: :sessions do
    get 'login', action: :login_form, as: :login
    post 'login', action: :login_post, as: :login_post
    get 'reauthenticate', action: :reauthenticate_form, as: :reauthenticate_form
    get 'logout', action: :logout, as: :logout
    get 'exit_accounts', action: :exit_accounts
  end

  scope controller: :signup do
    # welcome! choose a role!
    get 'signup', action: :welcome, as: :signup

    # step 1 - basic info about the user
    get 'signup/start', action: :signup_form, as: :signup_form
    post 'signup/start', action: :signup_post, as: :signup_post

    # step 2 - verify email, allow changing if necessary
    get 'signup/email_verification_form', action: :verify_email_by_pin_form, as: :verify_email_by_pin_form
    post 'signup/email_verification_form', action: :verify_email_by_pin_post, as: :verify_email_by_pin_post
    get 'signup/change_signup_email', action: :change_signup_email_form, as: :change_signup_email_form
    post 'signup/change_signup_email', action: :change_signup_email_post, as: :change_signup_email_post

    # signup complete!
    get 'done', action: :signup_done, as: :signup_done

    # verification actions that are not part of signup per se
    get 'verify_email_by_code/:code', action: :verify_email_by_code, as: :verify_email_by_code
    get 'check_your_email', action: :check_your_email, as: :check_your_email
  end

  scope controller: :educator_signup do
    # Step 3
    get 'signup/educator/apply', action: :sheerid_form, as: :sheerid_form
    post 'sheerid/webhook', action: :sheerid_webhook, as: :sheerid_webhook

    # Step 4
    get 'signup/educator/profile_form', action: :profile_form, as: :profile_form
    post 'signup/educator/complete_profile', action: :profile_post, as: :profile_post
    get 'signup/educator/pending_cs_verification', action: :pending_cs_verification_form, as: :cs_verification

    get 'signup/educator/cs_form', action: :pending_cs_verification_form, as: :cs_verification_form
    post 'signup/educator/cs_verification_request', action: :pending_cs_verification_post, as: :cs_verification_post
  end

  scope controller: :passwords, path: 'password', as: 'password' do
    get 'reset'
    post 'reset'

    post 'send_reset'
    post 'send_add'

    get 'add'
    post 'add'

    get 'reset_success'
    get 'add_success'

    get 'continue'
  end

  scope controller: :social_auth do
    get 'auth/:provider', action: :oauth_callback, as: :social_auth
    post 'auth/:provider', action: :oauth_callback
    get 'auth/:provider/callback', action: :oauth_callback
    delete 'auth/:provider', action: :remove_auth_strategy
    #   When you sign up with a social provider, you must confirm your info first
    get 'confirm_oauth_info', action: :confirm_oauth_info
    post 'confirm_oauth_info', action: :confirm_oauth_info
  end

  # Create a named path for links like `/auth/facebook` so that the path prefixer gem
  #     will appropriately prefix the path. https://stackoverflow.com/a/40125738/1664216
  # The actual request, however, is handled by the omniauth middleware when it detects
  #     that the current_url is the callback_path, using `OmniAuth::Strategy#on_callback_path?`
  #     So, admittedly, this route is deceiving.
  get '/auth/:provider', to: ->(_env) { [404, {}, ['Not Found']] }, as: :oauth



  resources :contact_infos, only: [:create, :destroy] do
    member do
      put 'set_searchable'
      put 'resend_confirmation'
    end
  end

  scope controller: 'contact_infos' do
    get 'confirm'
  end

  resources :terms, only: [:index, :show] do
    collection do
      get 'pose'
      post 'agree', as: 'agree_to'
    end
  end

  scope controller: 'static_pages' do
    get 'copyright'
    get 'api'
  end

  mount OpenStax::Api::Engine, at: '/'

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

  use_doorkeeper

  mount FinePrint::Engine => 'admin/fine_print'
  mount Blazer::Engine, at: 'admin/blazer', as: 'blazer_admin'
  match "admin/job_dashboard" => DelayedJobWeb, :anchor => false, :via => [:get, :post]
  mount OpenStax::Utilities::Engine => :status

  namespace 'admin' do
    get '/console', to: 'console#index'

    put 'cron', to: 'base#cron'
    get 'raise_exception/:type', to: 'base#raise_exception', as: 'raise_exception'

    resources :users, only: [:index, :update, :edit] do
      post 'become', on: :member
      get 'search', on: :collection
      get 'js_search', on: :collection
      get 'actions', on: :collection
      put 'mark_users_updated', on: :collection
    end

    resource :security_log, only: [:show]

    delete :delete_contact_info, path: '/contact_infos/:id/verify', controller: :contact_infos, action: :destroy
    post :verify_contact_info, path: '/contact_infos/:id/verify', controller: :contact_infos, action: :verify
  end

  namespace 'dev' do
    resources :users, only: [:create] do
      post 'generate', on: :collection
    end
  end

  if Rails.env.test?
    get '/external_app_for_specs' => 'external_app_for_specs#index'
    get '/external_app_for_specs/public' => 'external_app_for_specs#public'
  end
end
# rubocop:enable Metrics/BlockLength
