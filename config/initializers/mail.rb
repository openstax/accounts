Mail.defaults do
  delivery_method :smtp, SECRET_SETTINGS[:smtp_settings].symbolize_keys || {}
end
