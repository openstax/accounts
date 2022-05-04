class SessionsLookupLogin

  lev_handler

  paramify :login do
    attribute :username_or_email, type: String
    validates :username_or_email, presence: true
  end

  uses_routine GetLoginInfo,
               translations: { outputs: { type: :verbatim },
                               inputs:  { scope: :login } }

  protected

  def authorized?
    true
  end

  def handle
    run(GetLoginInfo, username_or_email: login_params.username_or_email)
  end

end
