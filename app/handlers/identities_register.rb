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
               translation: { scope: :register }

  uses_routine CreateIdentity,
               translation: { scope: :register }

protected

  def authorized?; true; end

  def handle
    run(CreateUser, 
        first_name: register_params.first_name,
        last_name:  register_params.last_name,
        username:   register_params.username
    ).tap do |outcome|
      results[:user] = outcome.results[:user]
    end

    run(CreateIdentity, 
        password:              register_params.password,
        password_confirmation: register_params.password_confirmation,
        user_id:               results[:user].id
    ).tap do |outcome|
      results[:identity] = outcome.results[:identity]
    end
  end

end