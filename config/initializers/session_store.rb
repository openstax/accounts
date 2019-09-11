# Be sure to restart your server when you modify this file.

# Permanent cookie jar also uses 20 years

class SessionStoreCookieName
  def self.to_s
    environment_name = Rails.application.secrets.environment_name
    "_accounts_session#{'_' + environment_name if environment_name != 'prodtutor'}"
  end
end

Rails.application.config.session_store :cookie_store, key: SessionStoreCookieName.to_s,
                                                      expire_after: 20.years,
                                                      domain: :all
