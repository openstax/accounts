accounts = ActiveSupport::OrderedOptions.new
# configure how long a login token is valid for
accounts.default_login_token_expiration_period = 2.days
# configure how long a password is valid for
accounts.default_password_expiration_period = nil
Rails.application.config.accounts = accounts
