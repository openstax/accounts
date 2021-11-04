class SignupVerifyEmail

  lev_handler

  uses_routine ConfirmByPin
  uses_routine SignupExternalStudent, translations: { outputs: { type: :verbatim } }

  paramify :pin do
    attribute :pin, type: String
    validates :pin, presence: true
  end

  def authorized?
    true
  end

  def handle
    run(ConfirmByPin)
  end

end
