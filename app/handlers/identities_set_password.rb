class IdentitiesSetPassword

  lev_handler

  paramify :set_password do
    attribute :password, type: String
    validates :password, presence: true
  end

  uses_routine SetPassword

  protected

  def authorized?
    !caller.is_anonymous?
  end

  def handle
    run(SetPassword, user: caller, password: set_password_params.password )
  end
end
