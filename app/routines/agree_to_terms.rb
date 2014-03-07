class AgreeToTerms

  lev_routine

protected

  def exec(contract_or_id, user)
    signature = FinePrint.sign_contract(user, contract_or_id)
    transfer_errors_from(signature, {type: :verbatim})
  end

end
