# rubocop:disable Metrics/BlockLength
Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root to: 'static_pages#home'

  direct :salesforce_knowledge_base do
    'https://openstax.secure.force.com/help/articles/FAQ/Can-t-log-in-to-your-OpenStax-account'
  end

  scope controller: 'newflow/other' do
    # Profile access
    get 'i/profile', action: :profile_newflow, as: :profile_newflow

    # Exit accounts back to app they came from
    get 'i/exit_accounts', action: :exit_accounts, as: :exit_accounts
  end

  scope controller: 'newflow/login' do
    get 'i/login', action: :login_form, as: :newflow_login
    post 'i/login', action: :login
    get 'i/reauthenticate', action: :reauthenticate_form, as: :reauthenticate_form
    get 'i/signout', action: :logout, as: :newflow_logout
  end

  scope controller: 'newflow/signup' do
    get 'i/signup', action: :welcome, as: :newflow_signup
    get 'i/done', action: :signup_done, as: :signup_done
    get 'i/verify_email_by_code/:code', action: :verify_email_by_code, as: :verify_email_by_code
    get 'i/check_your_email', action: :check_your_email, as: :check_your_email
  end

  scope controller: 'newflow/student_signup' do
    get 'i/signup/student', action: :student_signup_form, as: :newflow_signup_student
    post 'i/signup/student', action: :student_signup, as: :newflow_signup_post

    get 'i/signup/student/email_verification_form', action: :student_email_verification_form, as: :student_email_verification_form
    post 'i/signup/student/change_signup_email', action: :student_change_signup_email, as: :student_change_signup_email
    get 'i/signup/student/email_verification_form_updated_email',
      action: :student_email_verification_form_updated_email,
      as: :student_email_verification_form_updated_email
    get 'i/signup/student/change_signup_email_form', action: :student_change_signup_email_form, as: :student_change_signup_email_form
    post 'i/signup/student/verify_email_by_pin', action: :student_verify_email_by_pin, as: :student_verify_pin
  end

  scope controller: 'newflow/educator_signup' do
    # Step 1
    get 'i/signup/educator', action: :educator_signup_form, as: :educator_signup
    post 'i/signup/educator', action: :educator_signup, as: :educator_signup_post
    get 'i/signup/educator/change_signup_email_form', action: :educator_change_signup_email_form, as: :educator_change_signup_email_form
    post 'i/signup/educator/change_signup_email', action: :educator_change_signup_email, as: :educator_change_signup_email

    # Step 2
    get 'i/signup/educator/email_verification_form', action: :educator_email_verification_form, as: :educator_email_verification_form
    get 'i/signup/educator/email_verification_form_updated_email',
      action: :educator_email_verification_form_updated_email,
      as: :educator_email_verification_form_updated_email
    post 'i/signup/educator/verify_email_by_pin', action: :educator_verify_email_by_pin, as: :educator_verify_pin

    # Step 3
    get 'i/signup/educator/apply', action: :educator_sheerid_form, as: :educator_sheerid_form
    post 'i/sheerid/webhook', action: :sheerid_webhook, as: :sheerid_webhook

    # Step 4
    get 'i/signup/educator/profile_form', action: :educator_profile_form, as: :educator_profile_form
    post 'i/signup/educator/complete_profile', action: :educator_complete_profile, as: :educator_complete_profile
    get 'i/signup/educator/pending_cs_verification', action: :educator_pending_cs_verification, as: :educator_pending_cs_verification
  end

  scope controller: 'newflow/password_management' do
    # Password management process (forgot,  change, or create password)
    get 'i/forgot_password_form', action: :forgot_password_form, as: :forgot_password_form
    post 'i/send_reset_password_email',
      action: :send_reset_password_email,
      as: :send_reset_password_email
    get 'i/reset_password_email_sent',
          action: :reset_password_email_sent,
          as: :reset_password_email_sent
    get 'i/create_password_form', action: :create_password_form, as: :create_password_form
    post 'i/create_password', action: :create_password, as: :create_password
    get 'i/change_password_form', action: :change_password_form, as: :change_password_form
    post 'i/change_password', action: :change_password, as: :change_password
  end

  scope controller: 'newflow/social_auth' do
    get 'i/auth/:provider', action: :oauth_callback, as: :newflow_auth
    post 'i/auth/:provider', action: :oauth_callback
    get 'i/auth/:provider/callback', action: :oauth_callback
    delete 'i/auth/:provider', action: :remove_auth_strategy
    #   When you sign up with a social provider, you must confirm your info first
    get 'i/confirm_your_info', action: :confirm_your_info
    post 'i/confirm_oauth_info', action: :confirm_oauth_info, as: :confirm_oauth_info

    # TODO: remove because we determined that this use case is unreachable
    # When social login fails
    # get 'i/social_login_failed', action: :social_login_failed, as: :newflow_social_login_failed
    # post 'send_password_setup_instructions',
    #      action: :send_password_setup_instructions,
    #      as: :send_password_setup_instructions
  end

  scope controller: 'legacy/sessions' do
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
  get '/auth/:provider', to: ->(_env) { [404, {}, ['Not Found']] }, as: :oauth

  scope controller: 'legacy/authentications' do
    delete 'auth/:provider', action: :destroy, as: :destroy_authentication
    get 'add/:provider', action: :add, as: :add_authentication
  end

  scope controller: 'legacy/signup' do
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

  scope controller: 'legacy/users' do
    get 'profile', action: :edit
    put 'profile', action: :update
  end

  scope 'signup', controller: 'legacy/signup', as: 'signup' do
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

  scope controller: 'legacy/identities', path: 'password', as: 'password' do
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

    get 'raise_exception/:type', to: 'dev#raise_exception' unless Rails.env.production?
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
    get '/external_app_for_specs/public' => 'external_app_for_specs#public'
  end
end
# rubocop:enable Metrics/BlockLength
