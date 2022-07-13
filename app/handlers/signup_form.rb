class SignupForm

  lev_handler

  uses_routine AgreeToTerms
  uses_routine CreateEmailForUser
  uses_routine SetPassword, translations: {
    outputs: {
      map:   { identity: :password },
      scope: :password
    }
  }

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
    attribute :country_code, type: String
  end

  def required_params
    if signup_params.role == 'instructor'
      [:email, :first_name, :last_name, :password, :phone_number, :terms_accepted]
    else
      # student
      [:email, :first_name, :last_name, :password].compact
    end
  end

  def authorized?
    true
    # caller.is_needs_profile?
  end

  def handle
    validate_presence_of_required_params
    return if errors?

    signup_email  = signup_params.email.squish!
    outputs.email = signup_email

    if LookupUsers.by_verified_email(signup_email).first
      fatal_error(
        code:             :email_taken,
        message:          I18n.t(:'login_signup_form.email_address_taken'),
        offending_inputs: :email
      )
    end

    user         = User.create(
      state:          :unverified,
      role:           signup_params.role,
      faculty_status: :incomplete_signup, # signify email is unverified for user
      first_name:         signup_params.first_name,
      last_name:          signup_params.last_name,
      phone_number:       signup_params.phone_number,
      receive_newsletter: signup_params.newsletter,
      source_application: options[:client_app]
    )
    outputs.user = user

    run(::SetPassword,
        user:                  user,
        password:              signup_params.password,
        password_confirmation: signup_params.password)

    # Agree to terms
    if options[:contracts_required]
      run(AgreeToTerms, signup_params.contract_1_id, user, no_error_if_already_signed: true)
      run(AgreeToTerms, signup_params.contract_2_id, user, no_error_if_already_signed: true)
    end

    if options[:is_bri_book]
      user.update!(is_b_r_i_user: true, title_1_school: signup_params.is_title_1_school)
    end

    run(CreateEmailForUser, signup_email, user)
  end

  private

  def validate_presence_of_required_params
    required_params.each do |param|
      if signup_params.send(param).blank?
        missing_param_error(param)
      end
    end
  end

  def missing_param_error(field)
    code    = "#{field}_is_blank".to_sym
    message = I18n.t(:"login_signup_form.#{code}")
    nonfatal_error(
      code:             code,
      message:          message,
      offending_inputs: field
    )
  end
end
