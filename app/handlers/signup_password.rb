class SignupPassword

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
    attribute :email_address, type: String
    validates :email_address, presence: true
    attribute :password, type: String
    validates :password, presence: true
    attribute :password_confirmation, type: String
    validates :password_confirmation, presence: true
    attribute :contract_1_id, type: Integer
    attribute :contract_2_id, type: Integer
  end

  uses_routine CreateUser,
               translations: { inputs: {scope: :signup} }
  uses_routine CreateIdentity,
               translations: { inputs:  {scope: :signup},
                               outputs: {type: :verbatim}  }
  uses_routine AddEmailToUser,
               translations: { inputs: {scope: :signup} }
  uses_routine AgreeToTerms

  protected

  def authorized?
    OSU::AccessPolicy.action_allowed?(:signup, caller, caller)
  end

  def handle
    if options[:contracts_required] && !signup_params.i_agree
      fatal_error(code: :did_not_agree, message: (I18n.t :"handlers.signup_password.you_must_agree_to_the_terms"))
    end

    run(CreateUser, username: signup_params.username,
                    title: (signup_params.title if signup_params.title.blank?),
                    first_name: signup_params.first_name,
                    last_name: signup_params.last_name,
                    suffix: (signup_params.suffix if !signup_params.suffix.blank?),
                    state: 'activated')
    user = outputs[[:create_user, :user]]

    # Create an Identity, but not an Authentication -- that is done in SessionsCallback
    run(CreateIdentity,
        password:              signup_params.password,
        password_confirmation: signup_params.password_confirmation,
        user_id:               user.id
    )

    run(AddEmailToUser, signup_params.email_address, user)

    if options[:contracts_required]
      run(AgreeToTerms, signup_params.contract_1_id, user, no_error_if_already_signed: true)
      run(AgreeToTerms, signup_params.contract_2_id, user, no_error_if_already_signed: true)
    end
  end

end
