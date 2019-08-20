# Be sure to restart your server when you modify this file.

# Permanent cookie jar also uses 20 years
Rails.application.config.session_store :cookie_store, key: '_accounts_session',
                                                      expire_after: 20.years
