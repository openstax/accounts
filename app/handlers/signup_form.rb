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

  def authorized?
    true
    #caller.is_needs_profile?
  end

  def handle
    validate_presence_of_required_params
    return if errors?

    # this gets changed from 'educator' (for the url) to 'instructor' on the signup_form
    # will be student otherwise
    @selected_signup_role = signup_params.role.to_sym
    signup_email = signup_params.email.squish!

    outputs.email = signup_email

    if LookupUsers.by_verified_email(signup_email).first
      fatal_error(
        code:             :email_taken,
        message:          I18n.t(:"login_signup_form.email_address_taken"),
        offending_inputs: :email
      )
    end

    new_user = create_user

    run(::SetPassword,
        user:                  new_user,
        password:              signup_params.password,
        password_confirmation: signup_params.password
    )

    # Agree to terms
    if options[:contracts_required]
      run(AgreeToTerms, signup_params.contract_1_id, new_user, no_error_if_already_signed: true)
      run(AgreeToTerms, signup_params.contract_2_id, new_user, no_error_if_already_signed: true)
    end

    if options[:is_BRI_book]
      new_user.update!(is_b_r_i_user: true, title_1_school: signup_params.is_title_1_school)
    end

    run(CreateEmailForUser, signup_email, new_user)

    outputs.user = new_user
  end

  private

  def validate_presence_of_required_params

    if @selected_signup_role == 'instructor'
      required_params ||= [:email, :first_name, :last_name, :password, :phone_number, :terms_accepted]
    else
      required_params ||= [:email, :first_name, :last_name, :password].compact
    end

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

  def create_user
    if @selected_signup_role == 'instructor'
      role           = :instructor
      faculty_status = :incomplete_signup
    else
      role           = :student
      faculty_status = :no_faculty_info
    end

    user = User.create(
      state: :unverified,
      role: role,
      faculty_status: faculty_status,
      first_name: signup_params.first_name,
      last_name: signup_params.last_name,
      phone_number: signup_params.phone_number,
      receive_newsletter: signup_params.newsletter,
      source_application: options[:client_app]
    )
    transfer_errors_from(user, { type: :verbatim }, :fail_if_errors)
    user
  end

end
