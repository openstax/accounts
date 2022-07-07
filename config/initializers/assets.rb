# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.1'

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
Rails.application.config.assets.precompile += %w(
  admin.css
  admin.js
  profile.js
  application_body_api_docs.css
  intTelInput.css
  libphonenumber/utils.js
  syntax_highlight.css
  newflow.css
  newflow_colors.css
  newflow.js
  profile-nf.css
  application/ko_extensions.js
  bootstrap-editable-rails.js
  bootstrap-social.css
  pagination.css
)
