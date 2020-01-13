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

      validates :first_name, presence: true
      validates :last_name, presence: true
      validates :email, presence: true
      validates :password, presence: true
    end

  protected #################

    def authorized?
      true
    end

    def handle
      if LookupUsers.by_verified_email(signup_params.email).first
        fatal_error(
          code: :email_taken,
          message: I18n.t(:"login_signup_form.email_address_taken"),
          offending_inputs: :email
        )
      end

      create_user
      create_identity
      create_authentication
      agree_to_terms
      create_email_address
      send_confirmation_email
      push_lead_to_salesforce
    end

  private ###################

    def create_user
      outputs.user = User.create(
        state: 'unverified',
        role: 'student',
        first_name: signup_params.first_name.camelize,
        last_name: signup_params.last_name.camelize
      )
      transfer_errors_from(outputs.user, { type: :verbatim }, :fail_if_errors)
    end

    def create_identity
      identity = Identity.create(
        password: signup_params.password,
        password_confirmation: signup_params.password,
        user: outputs.user
      )
      transfer_errors_from(identity, { scope: :password }, :fail_if_errors)
    end

    def create_authentication
      authentication = Authentication.create(
        provider: 'identity',
        user_id: outputs.user.id, uid: outputs.user.identity.id
      )
      transfer_errors_from(authentication, { scope: :email }, :fail_if_errors)
      # TODO: catch error states like if auth already exists for this user
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
        transfer_errors_from(@email, { scope: :email }, :fail_if_errors)
      end
    end

    def send_confirmation_email
      NewflowMailer.signup_email_confirmation(email_address: @email).deliver_later
    end

    def push_lead_to_salesforce
      if Settings::Salesforce.push_leads_enabled
        PushSalesforceLead.perform_later(
          user: outputs.user,
          role: 'student',
          newsletter: signup_params.newsletter, # optionally subscribe to newsletter
          source_application: options[:client_app],
          # params req'd by the class but not by our business logic for students:
          url: nil, school: nil, using_openstax: nil, subject: nil, phone_number: nil, num_students: nil
        )
      end
    end
  end
end
