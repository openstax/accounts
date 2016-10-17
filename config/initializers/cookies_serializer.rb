# Be sure to restart your server when you modify this file.

# Applications created before Rails 4.1 uses Marshal to serialize cookie values into the signed and encrypted cookie jars.
# `:hybrid` will transparently migrate any existing Marshal-serialized cookies into the new JSON-based format.
# http://guides.rubyonrails.org/upgrading_ruby_on_rails.html#cookies-serializer
Rails.application.config.action_dispatch.cookies_serializer = :hybrid
