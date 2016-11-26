class IdentitiesSetPassword

  lev_handler

  paramify :set_password do
    attribute :password, type: String
    attribute :password_confirmation, type: String

    validates :password, presence: true
    validates :password_confirmation, presence: true
  end

  uses_routine SetPassword

  protected

  def authorized?
    !caller.is_anonymous?
  end

  def handle
    run(SetPassword, user: caller,
                     password: set_password_params.password,
                     password_confirmation: set_password_params.password_confirmation )
  end
end
