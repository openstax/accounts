module OmniAuth
  module Strategies
    # This class is a tweaked version of the OmniAuth-Identity strategy
    #
    # Notes:
    #   We could have implemented a `request_phase` method that displayed
    #   a signup form (e.g. by delegating to `SessionsController.action(:start).call(env)`),
    #   but instead we bypassed that step and just have our form post to
    #   `/auth/identity/signup`
    #
    #
    class CustomIdentity

      NullSession = ActionController::RequestForgeryProtection::ProtectionMethods::NullSession

      include OmniAuth::Strategy
      include UserSessionManagement
      include ContractsNotRequired
      include RateLimiting

      # Request forgery protection
      include ActiveSupport::Configurable
      include ActionController::RequestForgeryProtection

      # This is defined in RequestForgeryProtection, but since this file isn't ActionController
      # it doesn't pick up that code's setting, which is what we want so this CustomIdentity
      # has the same CSRF behavior as controllers
      def protect_against_forgery?
        ActionController::Base.allow_forgery_protection
      end

      #
      # Strategy stuff
      #

      option :fields, [:username, :first_name, :last_name]
      option(:locate_conditions, lambda do |req|
        users = LookupUsers.by_email_or_username(
          req.params['login'].try(:[], 'username_or_email')
        )
        users_returned = users.size
        user = users.first if users_returned == 1
        user_id = user.try :id

        { user: user, user_id: user_id, users_returned: users_returned }
      end)
      option :name, "identity"

      uid { identity.uid }
      info { identity.info }

      def too_many_login_attempts?
        too_many_log_in_attempts_by_ip?(ip: request.ip) ||
        too_many_log_in_attempts_by_user?(user: locate_conditions[:user])
      end

      def fail_with_log!(reason)
        SecurityLog.create!(
          user: locate_conditions[:user],
          remote_ip: request.ip,
          event_type: :sign_in_failed,
          event_data: { reason: reason.to_s }
        )

        fail!(reason.to_sym)
      end

      def callback_phase
        return fail_with_log!(:too_many_login_attempts) if too_many_login_attempts?

        if identity.present?
          # Give signup_state a chance to record the link if one exists
          signup_state.on_user_authentication(identity.user) if signup_state
          super
        else
          reason = if locate_conditions[:users_returned] == 0
            :cannot_find_user
          elsif locate_conditions[:users_returned] > 1
            :multiple_users
          else
            source = request.params.try(:[],"login").try(:[],"source")

            case source
            when "authenticate"
              :bad_authenticate_password
            when "reauthenticate"
              :bad_reauthenticate_password
            else
              raise IllegalArgument, "Unknown password error source: #{source || 'nil'}"
            end
          end

          fail_with_log!(reason)
        end
      end

      def other_phase
        if on_signup_path?
          # Normal identity shows sign up form on GET, but we don't want that
          request.post? ? handle_signup : raise(ActionController::RoutingError.new('Not Found'))
        else
          call_app!
        end
      end

      def verified_request?
        !protect_against_forgery? || request.get? || request.head? ||
        valid_authenticity_token?(session, form_authenticity_param) ||
        valid_authenticity_token?(session, request.env['X_CSRF_TOKEN'])
      end

      def form_authenticity_param
        request.params[request_forgery_protection_token.to_s]
      end

      def handle_unverified_request
        rq = ActionDispatch::Request.new(request.env)
        rq.session = NullSession::NullSessionHash.new(rq.env)
        rq.env['action_dispatch.request.flash_hash'] = nil
        rq.env['rack.session.options'] = { skip: true }
        rq.env['action_dispatch.cookies'] = NullSession::NullCookieJar.build(rq)
      end

      def handle_signup
        unless verified_request?
          Rails.logger.warn{ "Can't verify CSRF token authenticity" } \
            if Rails.logger && log_warning_on_csrf_failure

          handle_unverified_request
          SessionsController.action(:start).call(env)
        else
          @handler_result =
            SignupPassword.handle(
              params: request,
              caller: current_user,
              signup_state: signup_state
            )

          env['errors'] = @handler_result.errors

          if @handler_result.errors.none?
            @identity = @handler_result.outputs[:identity]
            env['PATH_INFO'] = callback_path
            callback_phase
          else
            show_signup_password_form
          end
        end
      end

      def show_signup_password_form
        SignupController.action(:password).call(env)
      end

      def signup_path
        options[:signup_path] || "#{path_prefix}/#{name}/signup"
      end

      def on_signup_path?
        on_path?(signup_path)
      end

      def identity
        @identity ||= model.authenticate(
          locate_conditions.slice(:user_id),
          request.params['login'].try(:[], 'password')
        )
      end

      def locate_conditions
        @conditions ||= instance_exec(request, &options.locate_conditions).to_hash
      end

      def model
        options[:model] || ::Identity
      end
    end
  end
end
