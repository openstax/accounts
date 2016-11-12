class SignupPassword

  lev_handler

  paramify :signup do
    attribute :password, type: String
    validates :password, presence: true
    attribute :password_confirmation, type: String
    validates :password_confirmation, presence: true
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
    user = User.create(state: 'needs_profile') # TODO take out state if before_create stays in user.rb
    transfer_errors_from(user, {type: :verbatim}, true)

    # Create an Identity, but not an Authentication -- that is done in SessionsCreate
    run(CreateIdentity,
        password:              signup_params.password,
        password_confirmation: signup_params.password_confirmation,
        user_id:               user.id
    )

    run(TransferSignupContactInfo, options[:signup_contact_info], user)
  end

end
