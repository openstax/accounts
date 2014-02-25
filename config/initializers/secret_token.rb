# Be sure to restart your server when you modify this file.

# Your secret key for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
Accounts::Application.config.secret_token = 
  SECRET_SETTINGS[:secret_token] || 'f311708fb1dfa965f0911e4a3adb3cfc5998f1705d0713b66290eb848af5c7f5d6930b1ecfbbf9f1e1a2c27068acd7f42b542c7a1fdebe428b0d0a180fa55c35'
