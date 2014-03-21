class AgreeToTerms

  lev_routine

protected

  def exec(contract_or_id, user, options={})
    return if options[:no_error_if_already_signed] && FinePrint.signed_contract?(user, contract_or_id)
    
    signature = FinePrint.sign_contract(user, contract_or_id)
    transfer_errors_from(signature, {type: :verbatim})
  end

end
