# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.1'

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
Rails.application.config.assets.precompile += %w(
  admin.js
  profile.js
  remote-access.js
  libphonenumber/utils.js
  application/ko_extensions.js
  application/phones-number.js
  admin.css
  intTelInput.css
  syntax_highlight.css
  common_colors.css
  profile.css
  application_body_api_docs.css
  bootstrap-editable/loading.gif
  bootstrap-editable/clear.png
  pattern-library
  pattern-library/headers
)
