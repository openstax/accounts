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

    # providers is hash where the keys are providers, and the values are product-
    # specific info.  E.g. for google, the value is a login hint that helps
    # google know which account is being targeted.
    outputs.providers = Authentication.where{user_id.in users.map(&:id)}
                                      .each_with_object({}) do |authentication, hash|
      provider = authentication.provider
      hash[provider] =
        case provider
        when 'google_oauth2'
          # the google login hint is an email; only leak this info if the user
          # already provided it as the way they are logging in.
          authentication.login_hint == login_params.username_or_email ?
            authentication.login_hint :
            authentication.uid
        else
          nil
        end
    end
  end
end
