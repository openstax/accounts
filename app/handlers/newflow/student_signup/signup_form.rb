module Newflow
  module StudentSignup
    class SignupForm

      lev_handler

      uses_routine AgreeToTerms
      uses_routine CreateEmailForUser

      paramify :signup do
        attribute :first_name, type: String
        attribute :last_name, type: String
        attribute :email, type: String
        attribute :password, type: String
        attribute :is_title_1_school, type: boolean
        attribute :newsletter, type: boolean
        attribute :terms_accepted, type: boolean
        attribute :contract_1_id, type: Integer
        attribute :contract_2_id, type: Integer
        attribute :role, type: String
        attribute :phone_number, type: String
      end

      protected #############

      def authorized?
        true
      end

      def required_params
        @required_params ||= [
          :email, :first_name, :last_name,

          if options[:user_from_signed_params].blank?
            :password
          end
        ].compact
      end

      def handle
        validate_presence_of_required_params
        return if errors?

        outputs.email = signup_params.email

        if LookupUsers.by_verified_email(signup_params.email).first
          fatal_error(
            code: :email_taken,
            message: I18n.t(:"login_signup_form.email_address_taken"),
            offending_inputs: :email
          )
        end

        if options[:user_from_signed_params].present?
          outputs.user = User.find_by!(id: options[:user_from_signed_params]['id'])
        else
          outputs.user = create_user

          run(::SetPassword,
            user: outputs.user,
            password: signup_params.password,
            password_confirmation: signup_params.password
          )
        end

        agree_to_terms

        if options[:is_BRI_book]
          outputs.user.is_b_r_i_user = true
          outputs.user.title_1_school = signup_params.is_title_1_school
          outputs.user.save!
        end

        agree_to_BRI_marketing if options[:is_BRI_book]
        run(CreateEmailForUser, email: signup_params.email, user: outputs.user)
      end

      private ###############

      def agree_to_BRI_marketing
        outputs.user.update!(is_b_r_i_user: true)
      end

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
          state: 'unverified',
          role: :student,
          first_name: signup_params.first_name,
          last_name: signup_params.last_name,
          phone_number: signup_params.phone_number,
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
