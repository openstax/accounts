class SessionsLookupLogin

  lev_handler

  paramify :login do
    attribute :username_or_email, type: String
    validates :username_or_email, presence: true
  end

  uses_routine GetLoginInfo,
               translations: { outputs: { type: :verbatim },
                               inputs: { type: :verbatim } }

  protected

  def authorized?
    true
  end

  def handle
    run(GetLoginInfo, username_or_email: login_params.username_or_email)
    fatal_error(code: :several_accounts_for_one_email) if input_is_email? && outputs.names.many?
  end


  def input_is_email?
    login_params.username_or_email.include?('@')
  end
end
