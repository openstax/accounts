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

  uses_routine CreateUser

protected

  def authorized?; true; end

  def exec
    user = run(CreateUser, register_params.as_hash([:first_name, :last_name, :username]))

    # user = User.create do |user|
    #   user.first_name = register_params.first_name
    #   user.last_name = register_params.last_name
    #   user.username = register_params.username
    # end
  
    transfer_errors_from(user, :register)

    return if errors.any?

    identity = Identity.create do |identity|
      identity.password = register_params.password
      identity.password_confirmation = register_params.password_confirmation
      identity.user_id = user.id
    end

    transfer_errors_from(identity, :register)

    results[:user] = user
    results[:identity] = identity
  end

  def default_transaction_isolation
    Lev::TransactionIsolation.mysql_default
  end

end