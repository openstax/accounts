# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.1'

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
Rails.application.config.assets.precompile += %w(
  admin.js
  admin.css
  profile.css
  profile.js
  libphonenumber/utils.js
  jquery_extensions.js
  ko_extensions.js
  phones-number.js
  intTelInput.css
  syntax_highlight.css
  application_body_api_docs.css
  pattern-library
  pattern-library/headers
  font-awesome
  bootstrap
  bootstrap-sprockets
)
