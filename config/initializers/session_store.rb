# Be sure to restart your server when you modify this file.

# Permanent cookie jar also uses 20 years

class SessionStoreCookieName
  def self.to_s
    "_accounts_session_#{Rails.application.secrets.environment_name}"
  end
end

Rails.application.config.session_store :cookie_store, key: SessionStoreCookieName.to_s,
                                                      expire_after: 20.years,
                                                      domain: :all
