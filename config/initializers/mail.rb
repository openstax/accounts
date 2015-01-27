Mail.defaults do
  delivery_method :smtp,
                  SECRET_SETTINGS[:smtp_settings].try(:symbolize_keys) || {}
end
