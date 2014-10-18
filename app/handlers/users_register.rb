class UsersRegister

  include Lev::Handler

  paramify :register do
    attribute :i_agree, type: boolean
    attribute :username, type: String
    attribute :first_name, type: String
    attribute :last_name, type: String
    attribute :full_name, type: String
    attribute :contract_1_id, type: Integer
    validates :contract_1_id, presence: true
    attribute :contract_2_id, type: Integer
    validates :contract_2_id, presence: true
  end

  uses_routine AgreeToTerms
  uses_routine FinishUserCreation

  protected

  def authorized?
    OSU::AccessPolicy.require_action_allowed!(:register, caller, caller)
    true
  end

  def handle
    if !register_params.i_agree
      fatal_error(code: :did_not_agree, message: 'You must agree to the terms to register') 
    end

    caller.username = register_params.username
    caller.first_name = register_params.first_name if !register_params.first_name.blank?
    caller.last_name = register_params.last_name if !register_params.last_name.blank?
    caller.full_name = register_params.full_name if !register_params.full_name.blank?
    caller.save

    transfer_errors_from(caller, {type: :verbatim}, true)

    run(AgreeToTerms, register_params.contract_1_id, caller, no_error_if_already_signed: true)
    run(AgreeToTerms, register_params.contract_2_id, caller, no_error_if_already_signed: true)

    run(FinishUserCreation, caller)
  end
end
