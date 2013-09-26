class IdentitiesRegister
  include Lev::Handler

  paramify :register do
    attribute :username, type: String
    # validates :username, presence: true

    attribute :first_name, type: String
    # validates :first_name, presence: true

    attribute :last_name, type: String
    # validates :last_name, presence: true

    attribute :password, type: String
    # validates :password, presence: true

    attribute :password_confirmation, type: String
    # validates :password_confirmation, presence: true
  end

  uses_routine CreateUser,
               translations: { inputs: {scope: :register} }

  uses_routine CreateIdentity,
               translations: { inputs:  {scope: :register}, 
                               outputs: {verbatim: true}  }

protected

  def authorized?; true; end

  def handle
    run(CreateUser, 
        first_name: register_params.first_name,
        last_name:  register_params.last_name,
        username:   register_params.username
    )

    run(CreateIdentity, 
        password:              register_params.password,
        password_confirmation: register_params.password_confirmation,
        user_id:               outputs[[:create_user, :user]].id
    )
  end

end