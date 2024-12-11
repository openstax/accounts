class CreateExternalUserCredentials
  lev_handler

  uses_routine AgreeToTerms
  uses_routine Newflow::CreateEmailForUser
  uses_routine SetPassword

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

  protected #############

  def authorized?
    !caller.is_anonymous? && caller.is_external?
  end

  def required_params
    @required_params ||= [:email, :first_name, :last_name, :password].compact
  end

  def handle
    validate_presence_of_required_params
    return if errors?

    outputs.email = signup_params.email.squish!
    outputs.user = caller

    fatal_error(
      code: :email_taken,
      message: I18n.t(:"login_signup_form.email_address_taken"),
      offending_inputs: :email
    ) if LookupUsers.by_verified_email(signup_params.email.squish!).first

    outputs.user.first_name = signup_params.first_name
    outputs.user.last_name = signup_params.last_name
    outputs.user.receive_newsletter = signup_params.newsletter
    outputs.user.role = :student
    outputs.user.save
    transfer_errors_from(outputs.user, { type: :verbatim }, :fail_if_errors)

    run(
      SetPassword,
      user: outputs.user,
      password: signup_params.password,
      password_confirmation: signup_params.password
    )

    run Newflow::CreateEmailForUser, email: signup_params.email, user: outputs.user, show_pin: false

    agree_to_terms if signup_params.terms_accepted
  end

  private ###############

  def validate_presence_of_required_params
    required_params.each do |param|
      missing_param_error(param) if signup_params.send(param).blank?
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

  def agree_to_terms
    run(AgreeToTerms, signup_params.contract_1_id, outputs.user, no_error_if_already_signed: true)
    run(AgreeToTerms, signup_params.contract_2_id, outputs.user, no_error_if_already_signed: true)
  end
end
