module OmniAuth
  module Strategies
    # This class is a tweaked version of the OmniAuth-Identity strategy
    class CustomIdentity
      include OmniAuth::Strategy

      option :fields, [:username, :first_name, :last_name]
      # option :on_login, nil
      # option :on_registration, nil
      # option :on_failed_registration, nil
      option :locate_conditions, lambda { |req|
        user = User.where(username: req.params['auth_key'])
        {user_id: (user.empty? ? nil : user.id)}
      }
      option :name, "identity"



      def request_phase
        SessionsController.action(:new).call(env)        
        # if options[:on_login]
        #   options[:on_login].call(self.env)
        # else
        #   OmniAuth::Form.build(
        #     :title => (options[:title] || "Identity Verification"),
        #     :url => callback_path
        #   ) do |f|
        #     f.text_field 'Login', 'auth_key'
        #     f.password_field 'Password', 'password'
        #     f.html "<p align='center'><a href='#{registration_path}'>Create an Identity</a></p>"
        #   end.to_response
        # end
      end

      def callback_phase
        return fail!(:invalid_credentials) unless identity
        super
      end

      def other_phase
        if on_registration_path?
          if request.get?
            registration_form
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
        @handler_outcome = IdentitiesRegister.handle({ params: request })

        if @handler_outcome.errors.empty?
          env['PATH_INFO'] = callback_path
          callback_phase
        else
          env['errors'] = @handler_outcome.errors
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
