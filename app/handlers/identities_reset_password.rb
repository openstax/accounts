class IdentitiesResetPassword

  lev_handler

  paramify :reset_password do
    attribute :password, type: String
    attribute :password_confirmation, type: String

    validates :password, presence: true
    validates :password_confirmation, presence: true
  end

  uses_routine SetPassword, translations: { outputs: { type: :verbatim } }

  protected

  def authorized?
    !caller.is_anonymous?
  end

  def handle
    run(SetPassword, user: caller,
                     password: reset_password_params.password,
                     password_confirmation: reset_password_params.password_confirmation )
  end
end
