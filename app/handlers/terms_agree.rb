class TermsAgree
  lev_handler

  paramify :agreement do
    attribute :i_agree, type: boolean
    attribute :contract_id, type: Integer
    validates :contract_id, presence: true
  end

  uses_routine AgreeToTerms

protected

  def authorized?
    true
  end

  def handle
    # In addition to doing whatever is needed to register a user, this page / handler
    # also gives the user a shortcut for agreeing to common site terms.

    if !agreement_params.i_agree
      fatal_error(code: :did_not_agree, message: 'You must agree to the terms to register') 
    end

    run(AgreeToTerms, agreement_params.contract_id, caller)
  end
end