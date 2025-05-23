# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
Rails.application.config.assets.precompile += %w(
  admin.css
  admin.js
  profile.js
  signup.js
  signin.js
  faculty_access.js
  remote-access.js
  bootstrap-editable/loading.gif
  bootstrap-editable/clear.png
  application_body_api_docs.css
  intTelInput.css
  libphonenumber/utils.js
  syntax_highlight.css
  newflow.css
  newflow_colors.css
  newflow.js
  newflow/educator_signup_email_validations.js
)
