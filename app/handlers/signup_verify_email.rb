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
    run(ConfirmByPin, contact_info: options[:signup_state], pin: pin_params.pin)
    # lms students do not receive passwords so the account needs to be created now
    if options[:signup_state].signed_student?
      run(SignupExternalStudent, options[:signup_state])
      options[:session].sign_in!(outputs.user)
    end
  end

end
