class StudentSignup
  lev_handler

  paramify :signup do
    attribute :first_name, type: String
    attribute :last_name, type: String
    attribute :email, type: String
    attribute :password, type: String
    attribute :newsletter, type: boolean
    attribute :terms_accepted, type: boolean
    attribute :contract_1_id, type: Integer
    attribute :contract_2_id, type: Integer

    validates :terms_accepted, acceptance: true
    validates :first_name, presence: true
    validates :last_name, presence: true
    validates :email, presence: true
    validates :password, presence: true
    validates :terms_accepted, presence: true
  end

  protected #################

  def authorized?
    true
  end

  def handle
    create_pre_auth_state
    create_user
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
      contact_info_value: signup_params.email,
      first_name: signup_params.first_name.camelize,
      role: 'student',
      # signed_data: existing_pre_auth_state.try!(:signed_data),
      # return_to: options[:return_to]
    )
  end

  def create_user
    outputs.user = User.create(
      first_name: signup_params.first_name.camelize,
      last_name: signup_params.last_name.camelize,
      state: 'activated', # TODO: or unclaimed?
      role: 'student'
    )
    transfer_errors_from(outputs.user, { type: :verbatim }, :fail_if_errors)
  end

  def create_authentication
    Authentication.create(
      provider: 'identity',
      # because of the way that user signup used to work in the old flow,
      # `user_id` and `uid` are both required and the same.
       user_id: outputs.user.id, uid: outputs.user.id
    )
    # TODO: catch errorr states like - if auth already exists for this user
  end

  def create_identity
    Identity.create(
      password: signup_params.password,
      password_confirmation: signup_params.password,
      user: outputs.user
    )
  end

  def agree_to_terms
    if options[:contracts_required] && signup_params.terms_accepted
      run(AgreeToTerms, signup_params.contract_1_id, outputs.user, no_error_if_already_signed: true)
      run(AgreeToTerms, signup_params.contract_2_id, outputs.user, no_error_if_already_signed: true)
    end
  end

  def create_email_address
    email = EmailAddress.new(
      value: signup_params.email, user_id: outputs.user.id,
      confirmation_pin: outputs.pre_auth_state.confirmation_pin
    )
    email.save
    transfer_errors_from(email, { type: :verbatim }, fail_if_errors=true)
  end

  def send_confirmation_email
    SignupConfirmationMailer.instructions(
      pre_auth_state: outputs.pre_auth_state
    ).deliver_later
  end
end
