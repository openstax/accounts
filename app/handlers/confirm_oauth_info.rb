class ConfirmOauthInfo
  lev_handler
  uses_routine AgreeToTerms

  paramify :info do
    attribute :first_name
    attribute :last_name
    attribute :email
    attribute :terms_accepted, type: boolean
    attribute :contract_1_id, type: Integer
    attribute :contract_2_id, type: Integer

    validates :first_name, presence: true
    validates :last_name, presence: true
    validates :email, presence: true
  end

  protected #################

  def authorized?
    true
  end

  def setup
    @user = options[:user]
  end

  def handle
    @user.update_attributes(state: 'activated')
    agree_to_terms(@user)
    # TODO: sign 'em up for the newsletter if checked
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
