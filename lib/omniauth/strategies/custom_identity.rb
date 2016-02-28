module OmniAuth
  module Strategies
    # This class is a tweaked version of the OmniAuth-Identity strategy
    class CustomIdentity
      include OmniAuth::Strategy

      #
      # Since this strategy is controller-like but from Rack, let's add
      # some current_user methods (for which we also need cookies)
      #

      include SignInState

      def cookies
        @cookies ||= ActionDispatch::Request.new(env).cookie_jar
      end

      #
      # Strategy stuff
      #

      option :fields, [:username, :first_name, :last_name]
      option :locate_conditions, lambda { |req|
        auth_key = req.params['auth_key']
        user = User.where(username: auth_key).first ||
               ContactInfo.where(value: auth_key).first.try(:user)
        {user_id: (user.nil? ? nil : user.id)}
      }
      option :name, "identity"

      def request_phase
        SessionsController.action(:new).call(env)
      end

      def callback_phase
        return fail!(:invalid_credentials) unless identity
        super
      end

      def other_phase
        if on_registration_path?
          if request.get?
            # Normal identity shows registration form, but we don't want that
            raise ActionController::RoutingError.new('Not Found')
          elsif request.post?
            registration_phase
          end
        else
          call_app!
        end
      end

      def registration_form
        IdentitiesController.action(:new).call(env)
      end

      def registration_phase
        @handler_result = IdentitiesRegister.handle(params: request,
                                                    caller: current_user)

        if @handler_result.errors.empty?
          @identity = @handler_result.outputs[:identity]
          env['PATH_INFO'] = callback_path
          callback_phase
        else
          env['errors'] = @handler_result.errors
          registration_form
        end
      end

      uid{ identity.uid }
      info{ identity.info }

      def registration_path
        options[:registration_path] || "#{path_prefix}/#{name}/register"
      end

      def on_registration_path?
        on_path?(registration_path)
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
