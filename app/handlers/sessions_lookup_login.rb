class SessionsLookupLogin

  lev_handler

  paramify :login do
    attribute :username_or_email, type: String
    validates :username_or_email, presence: true
  end

  protected

  def authorized?
    true
  end

  def handle
    users = LookupUsers.by_email_or_username(login_params.username_or_email)

    fatal_error(code: :unknown_username_or_email,
                message: I18n.t('errors.no_account_for_username_or_email'),
                offending_inputs: [:username_or_email]
               ) if users.empty?

    outputs.names = users.map(&:standard_name).uniq
    outputs.username_or_email = login_params.username_or_email
    outputs.providers = Authentication.where{user_id.in users.map(&:id)}
                                      .map(&:provider)
                                      .uniq
  end
end
