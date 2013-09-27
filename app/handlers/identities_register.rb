class IdentitiesRegister
  include Lev::Handler

  paramify :register do
    attribute :username, type: String
    attribute :first_name, type: String
    attribute :last_name, type: String
    attribute :password, type: String
    attribute :password_confirmation, type: String
  end

  uses_routine CreateUser,
               translations: { inputs: {scope: :register},
                               outputs: {type: :verbatim} }

  uses_routine CreateIdentity,
               translations: { inputs:  {scope: :register}, 
                               outputs: {type: :verbatim}  }

protected

  def authorized?;
    caller.is_anonymous?
  end

  def handle
    run(CreateUser, 
        first_name: register_params.first_name,
        last_name:  register_params.last_name,
        username:   register_params.username
    )

    run(CreateIdentity, 
        password:              register_params.password,
        password_confirmation: register_params.password_confirmation,
        user_id:               outputs[:user].id
    )

    authentication = Authentication.create(uid: outputs[:identity].id.to_s,
                                           provider: 'identity',
                                           user_id: outputs[:user].id)

    transfer_errors_from(authentication, {type: :verbatim})
  end

end