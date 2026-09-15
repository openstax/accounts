module Newflow
  module LearnerSignup
    # Deliberately minimal signup: reuses StudentSignup::SignupForm's shape and
    # helpers, but only requires an email + password. No name, school, or role
    # questions -- self-learners have no course/school affiliation to collect.
    #
    # The User model itself doesn't require first_name/last_name (they're
    # nullable columns with no presence validation), so we can leave them blank
    # here rather than inventing placeholder values.
    class SignupForm

      lev_handler

      uses_routine AgreeToTerms
      uses_routine CreateEmailForUser

      paramify :signup do
        attribute :email, type: String
        attribute :password, type: String
        attribute :newsletter, type: boolean
        attribute :terms_accepted, type: boolean
        attribute :contract_1_id, type: Integer
        attribute :contract_2_id, type: Integer
      end

      protected #############

      def authorized?
        true
      end

      def required_params
        @required_params ||= [:email, :password]
      end

      def handle
        validate_presence_of_required_params
        return if errors?

        outputs.email = signup_params.email.squish!

        if LookupUsers.by_verified_email(signup_params.email.squish!).first
          fatal_error(
            code: :email_taken,
            message: I18n.t(:"login_signup_form.email_address_taken"),
            offending_inputs: :email
          )
        end

        outputs.user = create_user

        run(::SetPassword,
            user: outputs.user,
            password: signup_params.password,
            password_confirmation: signup_params.password
        )

        agree_to_terms

        run(CreateEmailForUser, email: signup_params.email, user: outputs.user)
      end

      private ###############

      def validate_presence_of_required_params
        required_params.each do |param|
          if signup_params.send(param).blank?
            missing_param_error(param)
          end
        end
      end

      def missing_param_error(field)
        code = "#{field}_is_blank".to_sym
        message = I18n.t(:"login_signup_form.#{code}")
        nonfatal_error(
          code: code,
          message: message,
          offending_inputs: field
        )
      end

      def create_user
        user = User.create(
          state: User::UNVERIFIED,
          role: User::SELF_LEARNER_ROLE,
          receive_newsletter: signup_params.newsletter,
          source_application: options[:client_app],
          is_newflow: true
        )
        transfer_errors_from(user, { type: :verbatim }, :fail_if_errors)
        user
      end

      def agree_to_terms
        return unless options[:contracts_required]

        run(AgreeToTerms, signup_params.contract_1_id, outputs.user, no_error_if_already_signed: true)
        run(AgreeToTerms, signup_params.contract_2_id, outputs.user, no_error_if_already_signed: true)
      end
    end
  end
end
