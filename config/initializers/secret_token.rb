# Be sure to restart your server when you modify this file.

# Your secret key for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.

raise ArgumentError, 'Secret token not set' if Rails.env.production? && \
                                               !SECRET_SETTINGS[:secret_token]

Accounts::Application.config.secret_token = SECRET_SETTINGS[:secret_token] || \
  Digest::SHA1.hexdigest('not so secret token for development and testing only')
