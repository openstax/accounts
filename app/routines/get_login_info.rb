class GetLoginInfo

  lev_routine

  def exec(user: nil, username_or_email: nil)
    users =
      if user.present?
        [user]
      else
        if username_or_email.nil?
          raise IllegalArgument, "One of user or username_or_email must be given"
        end

        LookupUsers.by_email_or_username(username_or_email).tap do |users|
          fatal_error(code: :no_users, offending_inputs: :username_or_email) if users.empty?
        end
      end

    outputs.names = users.map(&:standard_name).uniq
    outputs.username_or_email = username_or_email

    # providers is hash where the keys are providers, and the values are product-
    # specific info.  E.g. for google, the value is a login hint that helps
    # google know which account is being targeted.
    outputs.providers = Authentication.where{user_id.in users.map(&:id)}
                                      .each_with_object({}) do |authentication, hash|
      provider = authentication.provider

      hash[provider] = { uid: authentication.uid }

      hash[provider][:login_hint] =
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
