# rubocop:disable Metrics/BlockLength
Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root to: 'static_pages#home'

  # routes to old faculty access controller, redirect them to the sheerid form or pending cs paths
  get 'faculty_access/apply/' => redirect('signup/educator/apply')
  get 'faculty_access/pending/' => redirect('signup/educator/pending_cs_verification')

  direct :salesforce_knowledge_base do
    'https://openstax.secure.force.com/help/articles/FAQ/Can-t-log-in-to-your-OpenStax-account'
  end

  scope controller: 'other' do
    # Profile access
    get 'profile'

    # Exit accounts back to app they came from
    get 'exit_accounts'
  end

  scope controller: 'login' do
    get 'login', action: :login_form, as: :login
    post 'login', action: :login
    get 'reauthenticate', action: :reauthenticate_form, as: :reauthenticate_form
    get 'logout'
  end

  scope controller: 'signup' do
    get 'signup', action: :welcome
    get 'done', action: :signup_done, as: :signup_done
    get 'verify_email_by_code/:code', action: :verify_email_by_code, as: :verify_email_by_code
    get 'check_your_email'
  end

  scope controller: 'student_signup' do
    get 'signup/student', action: :student_signup_form, as: :signup_student
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
    get 'signup/educator', action: :educator_signup_form, as: :educator_signup
    post 'signup/educator', action: :educator_signup, as: :educator_signup_post
    get 'signup/educator/change_signup_email_form', action: :educator_change_signup_email_form, as: :educator_change_signup_email_form
    post 'signup/educator/change_signup_email', action: :educator_change_signup_email, as: :educator_change_signup_email

    # Step 2
    get 'signup/educator/email_verification_form', action: :educator_email_verification_form, as: :educator_email_verification_form
    get 'signup/educator/email_verification_form_updated_email',
      action: :educator_email_verification_form_updated_email,
      as: :educator_email_verification_form_updated_email
    post 'signup/educator/verify_email_by_pin', action: :educator_verify_email_by_pin, as: :educator_verify_pin

    # Step 3
    get 'signup/educator/apply', action: :educator_sheerid_form, as: :educator_sheerid_form
    post 'sheerid/webhook', action: :sheerid_webhook, as: :sheerid_webhook

    # Step 4
    get 'signup/educator/profile_form', action: :educator_profile_form, as: :educator_profile_form
    post 'signup/educator/complete_profile', action: :educator_complete_profile, as: :educator_complete_profile
    get 'signup/educator/pending_cs_verification', action: :educator_pending_cs_verification, as: :educator_pending_cs_verification

    get 'signup/educator/cs_form', action: :educator_profile_form, as: :educator_cs_verification_form
    post 'signup/educator/cs_verification_request', action: :educator_complete_profile, as: :educator_cs_verification_request
  end

  scope controller: 'password_management' do
    # Password management process (forgot,  change, or create password)
    get 'forgot_password_form'
    post 'send_reset_password_email'
    get 'reset_password_email_sent'
    get 'create_password_form'
    post 'create_password'
    get 'change_password_form'
    post 'change_password'
  end

  scope controller: 'social_auth' do
    get 'auth/:provider', action: :oauth_callback
    post 'auth/:provider', action: :oauth_callback
    get 'auth/:provider/callback', action: :oauth_callback
    delete 'auth/:provider', action: :remove_auth_strategy, as: :destroy_authentication
    #   When you sign up with a social provider, you must confirm your info first
    get 'confirm_your_info'
    post 'confirm_oauth_info'
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
  get '/auth/:provider', to: ->(_env) { [404, {}, ['Not Found']] }, as: :auth

  # routes for access via an iframe
  scope 'remote', controller: 'remote' do
    get 'iframe'
    get 'notify_logout', as: 'iframe_after_logout'
  end

  scope controller: 'users' do
    put 'profile', action: :update
  end

  scope 'signup' do
    get '/' => redirect('signup')
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
  mount OpenStax::Utilities::Engine => :status

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
      post 'force_update_lead', on: :member
    end

    resource :reports, only: [:show]

    resource :security_log, only: [:show]

    delete :delete_contact_info, path: '/contact_infos/:id/verify',
                                 controller: :contact_infos, action: :destroy
    post :verify_contact_info, path: '/contact_infos/:id/verify',
                               controller: :contact_infos, action: :verify

    mount Blazer::Engine, at: 'blazer', as: 'blazer_admin'
    match "/job_dashboard" => DelayedJobWeb, :anchor => false, :via => [:get, :post]
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
