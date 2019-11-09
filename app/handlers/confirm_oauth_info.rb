class ConfirmOauthInfo
  lev_handler
  uses_routine AgreeToTerms

  paramify :info do
    attribute :first_name
    attribute :last_name
    attribute :terms_accepted, type: boolean
    attribute :contract_1_id, type: Integer
    attribute :contract_2_id, type: Integer

    validates :first_name, presence: true
    validates :last_name, presence: true
    validates :terms_accepted, presence: true
  end

  protected #################

  def authorized?
    true
  end

  def handle
    pre_auth_state = PreAuthState.find(options[:pre_auth_state].id)
    user = pre_auth_state.user
    user.update_attributes(state: 'activated')
    agree_to_terms(user)
    pre_auth_state.destroy

    outputs.user = user
  end

  private ###################

  def agree_to_terms(user)
    if options[:contracts_required]
      run(AgreeToTerms, info_params.contract_1_id, user, no_error_if_already_signed: true)
      run(AgreeToTerms, info_params.contract_2_id, user, no_error_if_already_signed: true)
    end
  end
end
