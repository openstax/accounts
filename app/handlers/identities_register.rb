class IdentitiesRegister

  lev_handler

  paramify :register do
    attribute :email, type: String
    validates :email, presence: true
    attribute :username, type: String
    attribute :first_name, type: String
    attribute :last_name, type: String
    attribute :password, type: String
    attribute :password_confirmation, type: String
  end

  uses_routine CreateUser,
               translations: { inputs: {scope: :register} }

  uses_routine CreateIdentity,
               translations: { inputs:  {scope: :register},
                               outputs: {type: :verbatim}  }

  uses_routine AddEmailToUser,
               translations: { inputs: {scope: :register} }

  protected

  def authorized?
    true
  end

  def handle
    user = caller

    if user.identity
      outputs[:identity] = user.identity # let the sign up flow continue
      fatal_error(code: :already_has_identity)
    end

    if user.is_anonymous?
      run(CreateUser,
          username:   register_params.username
      )
      user = outputs[[:create_user, :user]]
    end

    run(AddEmailToUser, register_params.email, user)
    if params[:stored_url].present?
      user.registration_redirect_url = params[:stored_url]
      user.save
    end

    run(CreateIdentity,
        password:              register_params.password,
        password_confirmation: register_params.password_confirmation,
        user_id:               user.id
    )

    authentication = Authentication.create(uid: outputs[:identity].id.to_s,
                                           provider: 'identity',
                                           user_id: user.id)

    transfer_errors_from(authentication, {type: :verbatim})
  end

end
