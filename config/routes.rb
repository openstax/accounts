# rubocop:disable Metrics/BlockLength
Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root to: 'static_pages#home'

  match 'i/(*path)' => redirect { |_,request| "/#{request.params[:path]}?#{request.params.except('path').to_query}" }, via: :all

  direct :salesforce_knowledge_base do
    'https://openstax.secure.force.com/help/articles/FAQ/Can-t-log-in-to-your-OpenStax-account'
  end

  scope controller: 'profile' do
    get 'profile', action: :profile, as: :profile
    get 'exit_accounts', action: :exit_accounts, as: :exit_accounts
  end

  scope controller: 'login' do
    get 'login', action: :login_form, as: :login
    post 'login', action: :login_post
    get 'reauthenticate', action: :reauthenticate_form, as: :reauthenticate_form
    get 'signout', action: :logout, as: :logout
  end

  scope controller: 'signup' do
    get 'signup', action: :welcome, as: :signup
    get 'done', action: :signup_done, as: :signup_done
    get 'verify_email_by_code/:code', action: :verify_email_by_code, as: :verify_email_by_code
    get 'check_your_email', action: :check_your_email, as: :check_your_email
  end

  scope controller: 'student_signup' do
    get 'signup/student', action: :student_signup, as: :signup_student
    post 'signup/student', action: :student_signup, as: :signup_post

    get 'signup/student/email_verification_form', action: :student_email_verification_form, as: :student_email_verification_form
    post 'signup/student/change_signup_email', action: :student_change_signup_email, as: :student_change_signup_email
    get 'signup/student/email_verification_form_updated_email',
      action: :student_email_verification_form_updated_email,
      as: :student_email_verification_form_updated_email
    get 'signup/student/change_signup_email_form', action: :student_change_signup_email_form, as: :student_change_signup_email_form
    post 'signup/student/verify_email_by_pin', action: :student_verify_email_by_pin, as: :student_verify_pin
  end

  scope controller: 'educator_signup' do
    # Step 1
    get 'signup/educator', action: :signup_form, as: :educator_signup_form
    post 'signup/educator', action: :signup_post, as: :educator_signup_post
    get 'signup/educator/change_signup_email', action: :change_signup_email_form, as: :educator_change_signup_email_form
    post 'signup/educator/change_signup_email', action: :change_signup_email_post, as: :educator_change_signup_email_post

    # Step 2
    get 'signup/educator/email_verification_form', action: :email_verification_form, as: :educator_email_verification_form
    get 'signup/educator/email_verification_form_updated_email', action: :email_verification_updated_email_form, as: :email_verification_updated_email_post
    post 'signup/educator/verify_email_by_pin', action: :verify_email_by_pin_post, as: :educator_verify_pin_post

    # Step 3
    get 'signup/educator/apply', action: :sheerid_form, as: :educator_sheerid_form
    post 'i/sheerid/webhook', action: :sheerid_webhook, as: :sheerid_webhook

    # Step 4
    get 'signup/educator/profile_form', action: :profile_form, as: :educator_profile_form
    post 'signup/educator/complete_profile', action: :profile_form_post, as: :educator_complete_profile_post
    get 'signup/educator/pending_cs_verification', action: :pending_cs_verification, as: :educator_pending_cs_verification_form

    get 'signup/educator/cs_form', action: :pending_cs_verification_form, as: :educator_cs_verification_form
    post 'signup/educator/cs_verification_request', action: :profile_form_post, as: :educator_cs_verification_post
  end

  scope controller: 'password_management' do
    # Password management process (forgot,  change, or create password)
    get 'forgot_password_form', action: :forgot_password_form, as: :forgot_password_form
    post 'send_reset_password_email',
      action: :send_reset_password_email,
      as: :send_reset_password_email
    get 'reset_password_email_sent',
          action: :reset_password_email_sent,
          as: :reset_password_email_sent
    get 'create_password_form', action: :create_password_form, as: :create_password_form
    post 'create_password', action: :create_password, as: :create_password
    get 'change_password_form', action: :change_password_form, as: :change_password_form
    post 'change_password', action: :change_password, as: :change_password
  end

  scope controller: 'social_auth' do
    get 'auth/:provider', action: :oauth_callback, as: :social_auth
    post 'auth/:provider', action: :oauth_callback
    get 'auth/:provider/callback', action: :oauth_callback
    delete 'auth/:provider', action: :remove_auth_strategy
    #   When you sign up with a social provider, you must confirm your info first
    get 'confirm_your_info', action: :confirm_your_info
    post 'confirm_oauth_info', action: :confirm_oauth_info, as: :confirm_oauth_info
  end

  scope controller: 'sessions' do
    get 'logout', action: :destroy

    # Maintain these deprecated routes for a while until client code learns to
    # use /login and /logout
    get 'signout', action: :destroy
  end

  mount OpenStax::Api::Engine, at: '/'

  # Create a named path for links like `/auth/facebook` so that the path prefixer gem
  #     will appropriately prefix the path. https://stackoverflow.com/a/40125738/1664216
  # The actual request, however, is handled by the omniauth middleware when it detects
  #     that the current_url is the callback_path, using `OmniAuth::Strategy#on_callback_path?`
  #     So, admittedly, this route is deceiving.
  get '/auth/:provider', to: ->(_env) { [404, {}, ['Not Found']] }, as: :oauth

  # routes for access via an iframe
  scope 'remote', controller: 'remote' do
    get 'iframe'
    get 'notify_logout', as: 'iframe_after_logout'
  end

  scope controller: 'users' do
    put 'profile', action: :update
  end

  scope controller: 'identities', path: 'password', as: 'password' do
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

  apipie

  api :v1, default: true do
    resources :users, only: [:index]

    resource :user, only: [:show, :update] do
      post '/find-or-create', action: 'find_or_create'
    end

    resources :application_users, only: [:index] do
      collection do
        #get 'find/username/:username', action: 'find_by_username'
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

    # resources :contact_infos, only: [] do
    #   member do
    #     put 'verify'
    #     delete 'destroy'
    #   end
    # end

    get 'raise_exception/:type', to: 'dev#raise_exception' unless Rails.env.production?
  end

  use_doorkeeper { controllers applications: 'oauth/applications' }

  mount FinePrint::Engine => '/admin/fine_print'
  mount OpenStax::Utilities::Engine => :status

  namespace 'admin' do
    get '/', to: 'base#index'
    get '/console', to: 'console#index'

    put 'cron',                         to: 'base#cron'
    get 'raise_exception/:type',        to: 'base#raise_exception', as: 'raise_exception'

    resources :users, only: [:index, :update, :edit] do
      post 'become', on: :member
      get 'search', on: :collection
      get 'actions', on: :collection
      put 'mark_users_updated', on: :collection
    end

    resource :reports, only: [:show]

    resource :security_log, only: [:show]

    delete :delete_contact_info, path: '/contact_infos/:id/verify',
                                 controller: :contact_infos, action: :destroy
    post :verify_contact_info, path: '/contact_infos/:id/verify',
                               controller: :contact_infos, action: :verify

    mount Blazer::Engine, at: 'blazer', as: 'blazer_admin'
    match "/job_dashboard" => DelayedJobWeb, :anchor => false, :via => [:get, :post]

    mount RailsSettingsUi::Engine, at: 'settings'
  end

  # namespace 'dev' do
  #   resources :users, only: [:create] do
  #     post 'generate', on: :collection
  #   end
  # end

  if Rails.env.test?
    get '/external_app_for_specs' => 'external_app_for_specs#index'
    get '/external_app_for_specs/public' => 'external_app_for_specs#public'
  end
end
# rubocop:enable Metrics/BlockLength
