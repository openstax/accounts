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
      option :locate_conditions, lambda { |req|
        auth_key = req.params['auth_key'].try(:strip)
        user = User.where(username: auth_key).first ||
               ContactInfo.where(value: auth_key).first.try(:user)
        {user_id: (user.nil? ? nil : user.id)}
      }
      option :name, "identity"

      uid { identity.uid }
      info { identity.info }

      def callback_phase
        return fail!(:invalid_credentials) unless identity
        super
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
            contracts_required: !contracts_not_required(client_id: request['client_id'] ||
                                                        session['client_id'])
          )

        error_codes = @handler_result.errors.map(&:code)
        env['errors'] = @handler_result.errors

        if error_codes.empty? || error_codes == [:already_has_identity]
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
        if options.locate_conditions.is_a? Proc
          conditions = instance_exec(request, &options.locate_conditions)
          conditions.to_hash
        else
          conditions = options.locate_conditions.to_hash
        end
        @identity ||= model.authenticate(conditions, request['password'] )
      end

      def model
        options[:model] || ::Identity
      end
    end
  end
end
