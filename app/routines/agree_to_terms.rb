class AgreeToTerms

  lev_routine

  protected

  def exec(contract_or_id, user, options={})
    fatal_error(code: :contract_not_specified) if contract_or_id.nil?

    return if options[:no_error_if_already_signed] && FinePrint.signed_contract?(user,
contract_or_id)

    signature = FinePrint.sign_contract(user, contract_or_id)
    transfer_errors_from(signature, {type: :verbatim})
  end

end
