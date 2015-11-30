class UsersRegister

  lev_handler

  paramify :register do
    attribute :i_agree, type: boolean
    attribute :username, type: String
    attribute :title, type: String
    attribute :first_name, type: String
    validates :first_name, presence: true
    attribute :last_name, type: String
    validates :last_name, presence: true
    attribute :suffix, type: String
    attribute :full_name, type: String
    attribute :contract_1_id, type: Integer
    attribute :contract_2_id, type: Integer
  end

  uses_routine AgreeToTerms
  uses_routine FinishUserCreation

  protected

  def authorized?
    OSU::AccessPolicy.action_allowed?(:register, caller, caller)
  end

  def handle
    if options[:contracts_required] && !register_params.i_agree
      fatal_error(code: :did_not_agree, message: 'You must agree to the terms to register')
    end

    caller.username = register_params.username
    caller.title = register_params.title if !register_params.title.blank?
    caller.first_name = register_params.first_name
    caller.last_name = register_params.last_name
    caller.suffix = register_params.suffix if !register_params.suffix.blank?
    caller.full_name = register_params.full_name if !register_params.full_name.blank?
    caller.save

    transfer_errors_from(caller, {type: :verbatim}, true)

    if options[:contracts_required]
      run(AgreeToTerms, register_params.contract_1_id, caller, no_error_if_already_signed: true)
      run(AgreeToTerms, register_params.contract_2_id, caller, no_error_if_already_signed: true)
    end

    run(FinishUserCreation, caller)
  end
end
