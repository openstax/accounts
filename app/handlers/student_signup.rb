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
      fatal_error(code: :email_taken, message: 'Email address taken', offending_inputs: :email)
    end

    create_user
    create_pre_auth_state
    create_authentication
    create_identity
    agree_to_terms
    create_email_address
    send_confirmation_email
  end

  private ###################

  def create_pre_auth_state
    outputs.pre_auth_state = PreAuthState.email_address.create(
      is_partial_info_allowed: true,
      contact_info_value: signup_params.email.downcase,
      first_name: signup_params.first_name.camelize,
      last_name: signup_params.last_name.camelize,
      role: 'student',
      user_id: outputs.user.id
      # signed_data: existing_pre_auth_state.try!(:signed_data),
      # return_to: options[:return_to]
    )
  end

  def create_user
    outputs.user = User.create(
      first_name: signup_params.first_name.camelize,
      last_name: signup_params.last_name.camelize,
      state: 'unverified',
      role: 'student'
    )
    transfer_errors_from(outputs.user, { type: :verbatim }, :fail_if_errors)
  end

  def create_authentication
    authentication = Authentication.create(
      provider: 'identity',
      # because of the way that user signup used to work in the old flow,
      # `user_id` and `uid` are both required and the same.
      user_id: outputs.user.id, uid: outputs.user.id
    )
    transfer_errors_from(authentication, { scope: :email_address }, :fail_if_errors)
    # TODO: catch error states like if auth already exists for this user
  end

  def create_identity
    Identity.create(
      password: signup_params.password,
      password_confirmation: signup_params.password,
      user: outputs.user
    )
  end

  def agree_to_terms
    if options[:contracts_required]
      run(AgreeToTerms, signup_params.contract_1_id, outputs.user, no_error_if_already_signed: true)
      run(AgreeToTerms, signup_params.contract_2_id, outputs.user, no_error_if_already_signed: true)
    end
  end

  def create_email_address
    email = EmailAddress.create(
      value: signup_params.email.downcase, user_id: outputs.user.id,
      confirmation_pin: outputs.pre_auth_state.confirmation_pin # TODO: is this okay and necessary?
    )
    transfer_errors_from(email, { scope: :email_adress }, :fail_if_errors)
  end

  def send_confirmation_email
    SignupConfirmationMailer.instructions(
      pre_auth_state: outputs.pre_auth_state
    ).deliver_later
  end
end
