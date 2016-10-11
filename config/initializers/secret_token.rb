# Be sure to restart your server when you modify this file.

# Your secret key for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.

raise ArgumentError, 'Secret token not set' if Rails.env.production? && \
                                               !SECRET_SETTINGS[:secret_token]

# You can use `rake secret` to generate a secure secret key.

# Make sure your secret_key_base is kept private
# if you're sharing your code publicly.
Accounts::Application.config.secret_token = SECRET_SETTINGS[:secret_token] || \
  Digest::SHA1.hexdigest('not so secret token for development and testing only')

# TODO: VERY IMPORTANT! CAREFUL WHEN SETTING THIS!
# http://edgeguides.rubyonrails.org/upgrading_ruby_on_rails.html#upgrading-from-rails-3-2-to-rails-4-0
# Accounts::Application.config.secret_key_base = SECRET_SETTINGS[:secret_key_base] || \
#   Digest::SHA1.hexdigest('not so secret key base for development and testing only')
