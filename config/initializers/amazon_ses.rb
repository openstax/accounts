if Rails.env.production? && !ActiveModel::Type::Boolean.new.cast(ENV.fetch('DISABLE_SES', false))
  secrets = Rails.application.secrets[:aws][:ses]

  creds = Aws::Credentials.new(secrets[:access_key_id], secrets[:secret_access_key])

  Aws::Rails.add_action_mailer_delivery_method(
    :ses,
    credentials: creds,
    region: secrets[:endpoint_server].split('.')[1]
  )
end
