class SignupSocial

  lev_handler

  paramify :signup do
    attribute :i_agree, type: boolean
    attribute :username, type: String
    validates :username, presence: true
    attribute :title, type: String
    attribute :first_name, type: String
    validates :first_name, presence: true
    attribute :last_name, type: String
    validates :last_name, presence: true
    attribute :suffix, type: String
    attribute :contract_1_id, type: Integer
    attribute :contract_2_id, type: Integer
  end

  uses_routine AgreeToTerms

  protected

  def authorized?
    OSU::AccessPolicy.action_allowed?(:register, caller, caller)
  end

  def handle
    user = caller

    if options[:contracts_required] && !signup_params.i_agree
      fatal_error(code: :did_not_agree, message: 'You must agree to the terms to create your account.')
    end

    user.username = signup_params.username
    user.title = signup_params.title if !signup_params.title.blank?
    user.first_name = signup_params.first_name
    user.last_name = signup_params.last_name
    user.suffix = signup_params.suffix if !signup_params.suffix.blank?
    user.state = 'activated'  # TODO should state already be activated?
    user.save

    transfer_errors_from(user, {type: :verbatim}, true)

    if options[:contracts_required]
      run(AgreeToTerms, signup_params.contract_1_id, user, no_error_if_already_signed: true)
      run(AgreeToTerms, signup_params.contract_2_id, user, no_error_if_already_signed: true)
    end
  end

end
