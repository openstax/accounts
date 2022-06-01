class SignupPassword

  lev_handler

  paramify :signup do
    attribute :password, type: String
    validates :password, presence: true
    attribute :password_confirmation, type: String
    validates :password_confirmation, presence: true
  end

  uses_routine CreateIdentity,
               translations: { inputs:  {scope: :signup},
                               outputs: {type: :verbatim}  }

  protected

  def authorized?
    OSU::AccessPolicy.action_allowed?(:signup, caller, caller)
  end

  def handle
    transfer_errors_from(outputs.user, {type: :verbatim}, true)

    # Create an Identity, but not an Authentication -- that is done in SessionsCreate
    run(CreateIdentity,
        password:              signup_params.password,
        password_confirmation: signup_params.password_confirmation,
        user_id:               outputs.user.id
       )
    transfer_errors_from(outputs.identity, {type: :verbatim}, true)
  end

end
