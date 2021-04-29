if Rails.env.production?
  secrets = Rails.application.secrets[:aws][:ses]

  creds = Aws::Credentials.new(secrets[:access_key_id], secrets[:secret_access_key])

  Aws::Rails.add_action_mailer_delivery_method(
    :ses,
    credentials: creds,
    region: 'us-west-2'
  )
end
