class NewflowStudentSignup
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

  protected

  def authorized?
    true
  end

  def handle
    outputs.pre_auth_state = create_pre_auth_state

    user = User.create(
      first_name: signup_params.first_name.camelize,
      last_name: signup_params.last_name.camelize,
      state: 'unclaimed',
      role: 'student'
    )
    transfer_errors_from(user, { type: :verbatim }, fail_if_errors=true)

    # Agree to terms
    if options[:contracts_required] && signup_params.terms_accepted
      run(AgreeToTerms, profile_params.contract_1_id, user, no_error_if_already_signed: true)
      run(AgreeToTerms, profile_params.contract_2_id, user, no_error_if_already_signed: true)
    end

    email = EmailAddress.new(
      value: signup_params.email, user_id: user.id,
      confirmation_pin: outputs.pre_auth_state.confirmation_pin
    )
    email.save!
    send_confirmation_email
  end

  def create_pre_auth_state
    PreAuthState.email_address.create(
      is_partial_info_allowed: true,
      contact_info_value: signup_params.email,
      first_name: signup_params.first_name.camelize,
      role: 'student',
      # signed_data: existing_pre_auth_state.try!(:signed_data),
      # return_to: options[:return_to]
    )
  end

  def send_confirmation_email
    SignupConfirmationMailer.instructions(
      pre_auth_state: outputs.pre_auth_state
    ).deliver_later
  end
end
