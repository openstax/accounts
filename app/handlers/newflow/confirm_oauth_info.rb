module Newflow
  class ConfirmOauthInfo
    lev_handler
    uses_routine CreateEmailForUser
    uses_routine AgreeToTerms
    uses_routine ActivateUser

    paramify :signup do
      attribute :first_name
      attribute :last_name
      attribute :email
      attribute :newsletter, type: boolean
      attribute :terms_accepted, type: boolean
      attribute :contract_1_id, type: Integer
      attribute :contract_2_id, type: Integer

      validates :first_name, presence: true
      validates :last_name, presence: true
      validates :email, presence: true
    end

    protected ###############

    def authorized?
      !@user.activated?
    end

    def setup
      @user = options[:user]
    end

    def handle
      return email_taken_error!(@user.id) if is_email_taken?(signup_params.email)

      if @user.email_addresses.none?
        run(CreateEmailForUser, email: signup_params.email, user: @user)
      end

      @user.update_attributes(
        first_name: signup_params.first_name,
        last_name: signup_params.last_name,
        receive_newsletter: signup_params.newsletter
      )
      transfer_errors_from(@user, {type: :verbatim}, :fail_if_errors)

      agree_to_terms(@user)
      run(ActivateUser, @user)

      outputs.user = @user
    end

    private #################

    def is_email_taken?(email)
      user_who_owns_email_address = LookupUsers.by_verified_email(email).first
      return false if user_who_owns_email_address.nil?

      Raven.capture_message('Email address taken during ConfirmOauthInfo', extra: { user_id: @user.id })
      user_who_owns_email_address.id != @user.id
    end

    def email_taken_error!(user_id)
      Raven.capture_message(
        'Email address taken during ConfirmOauthInfo',
        extra: { user_id: user_id }
      )

      fatal_error(
        code: :email_taken,
        message: I18n.t(:"login_signup_form.email_address_taken"),
        offending_inputs: :email
      )
    end

    def agree_to_terms(user)
      if options[:contracts_required]
        run(AgreeToTerms, signup_params.contract_1_id, user, no_error_if_already_signed: true)
        run(AgreeToTerms, signup_params.contract_2_id, user, no_error_if_already_signed: true)
      end
    end
  end
end
