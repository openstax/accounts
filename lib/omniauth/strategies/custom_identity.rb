module OmniAuth
  module Strategies
    # This class is a tweaked version of the OmniAuth-Identity strategy
    #
    # Notes:
    #   We could have implemented a `request_phase` method that displayed
    #   a signup form (e.g. by delegating to `SessionsController.action(:new).call(env)`),
    #   but instead we bypassed that step and just have our form post to
    #   `/auth/identity/signup`
    #
    #
    class CustomIdentity

      LOGIN_ATTEMPTS_PERIOD = 1.hour
      MAX_LOGIN_ATTEMPTS_PER_USER = 100
      MAX_LOGIN_ATTEMPTS_PER_IP = 10000

      include OmniAuth::Strategy

      #
      # Since this strategy is controller-like but from Rack, let's add
      # some current_user methods (for which we also need cookies)
      #

      include SignInState
      include ContractsNotRequired

      def cookies
        @cookies ||= ActionDispatch::Request.new(env).cookie_jar
      end

      #
      # Strategy stuff
      #

      option :fields, [:username, :first_name, :last_name]
      option(:locate_conditions, lambda do |req|
        auth_key = req.params['auth_key'].try(:strip)
        contacts = ContactInfo.verified.where(value: auth_key).preload(:user)
        users = [User.where(username: auth_key).first || contacts.map(&:user)].flatten
        users_returned = users.size
        user = users.first if users_returned == 1
        user_id = user.try :id

        { user: user, user_id: user_id, users_returned: users_returned }
      end)
      option :name, "identity"

      uid { identity.uid }
      info { identity.info }

      def too_many_login_attempts
        recent_time = Time.now - LOGIN_ATTEMPTS_PERIOD
        security_log_relation = SecurityLog.sign_in_failed.where{created_at > recent_time}

        remote_ip = request.ip
        ip_attempts = security_log_relation.where(remote_ip: remote_ip).count

        return true if ip_attempts >= MAX_LOGIN_ATTEMPTS_PER_IP

        user = locate_conditions[:user]
        user_attempts = user.nil? ? 0 : security_log_relation.where(user: user).count

        return true if user_attempts >= MAX_LOGIN_ATTEMPTS_PER_USER

        false
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
        return fail_with_log!(:too_many_login_attempts) if too_many_login_attempts

        if identity.present?
          super
        else
          reason = if locate_conditions[:users_returned] == 0
            :cannot_find_user
          elsif locate_conditions[:users_returned] > 1
            :multiple_users
          else
            :bad_password
          end

          fail_with_log!(reason)
        end
      end

      def other_phase
        if on_signup_path?
          if request.get?
            # Normal identity shows sign up form, but we don't want that
            raise ActionController::RoutingError.new('Not Found')
          elsif request.post?
            handle_signup
          end
        else
          call_app!
        end
      end

      def handle_signup
        @handler_result =
          SignupPassword.handle(
            params: request,
            caller: current_user,
            contracts_required: !contracts_not_required(
              client_id: request['client_id'] || session['client_id']
            )
          )

        env['errors'] = @handler_result.errors

        if @handler_result.errors.none?
          @identity = @handler_result.outputs[:identity]
          env['PATH_INFO'] = callback_path
          callback_phase
        else
          show_signup_form
        end
      end

      def show_signup_form
        SignupController.action(:password).call(env)
      end

      def signup_path
        options[:signup_path] || "#{path_prefix}/#{name}/signup"
      end

      def on_signup_path?
        on_path?(signup_path)
      end

      def identity
        @identity ||= model.authenticate(locate_conditions.slice(:user_id), request['password'])
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
