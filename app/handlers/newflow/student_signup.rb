module Newflow
  class StudentSignup
    lev_handler
    uses_routine AgreeToTerms

    paramify :signup do
      attribute :first_name, type: String
      attribute :last_name, type: String
      attribute :email, type: String
      attribute :password, type: String
      attribute :newsletter, type: boolean
      attribute :terms_accepted, type: boolean
      attribute :contract_1_id, type: Integer
      attribute :contract_2_id, type: Integer
    end

  protected #################

    def authorized?
      true
    end

    def handle
      new_login_credential_check
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

      create_email_address
      agree_to_terms
      send_confirmation_email
    end

    private ###################
    def new_login_credential_check
      [:email, :first_name, :last_name, :password].each do |param|
        if signup_params.send(param).blank?
          if param == :password
            missing_param_error(param) if options[:user_from_signed_params].blank?
          else
            missing_param_error(param)
          end
        end
      end
    end

    def missing_param_error(field)
      code = "#{field}_is_blank".to_sym
      message = I18n.t(:".activerecord.errors.models.identity.attributes.#{field}.blank")
      nonfatal_error(
        code: code,
        message: message,
        offending_inputs: field
      )
    end

    def create_user
      user = User.create(
        state: 'unverified',
        role: 'student',
        first_name: signup_params.first_name,
        last_name: signup_params.last_name,
        receive_newsletter: signup_params.newsletter,
        source_application: options[:client_app]
      )
      transfer_errors_from(user, { type: :verbatim }, :fail_if_errors)
      user
    end

    def agree_to_terms
      return unless options[:contracts_required]

      run(AgreeToTerms, signup_params.contract_1_id, outputs.user, no_error_if_already_signed: true)
      run(AgreeToTerms, signup_params.contract_2_id, outputs.user, no_error_if_already_signed: true)
    end

    def create_email_address
      @email = EmailAddress.create(
        value: signup_params.email.downcase, user_id: outputs.user.id
      )

      # Customize the error message about having an invalid email domain
      if @email.errors && @email.errors.types.fetch(:value, {}).include?(:missing_mx_records)
        domain = @email.send(:domain)
        @email.errors.messages[:value][0] = I18n.t(:"login_signup_form.invalid_email_provider", domain: domain)
      end

      transfer_errors_from(@email, { scope: :email }, :fail_if_errors)
    end

    def send_confirmation_email
      NewflowMailer.signup_email_confirmation(email_address: @email).deliver_later
    end
  end
end
