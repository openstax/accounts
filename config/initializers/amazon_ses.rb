require 'aws-sdk-core'

if Rails.env.production?
  secrets = Rails.application.secrets[:aws][:ses]

  Aws.config.update(
    region: 'us-west-2',
    credentials: Aws::Credentials.new(secrets[:access_key_id], secrets[:secret_access_key])
  )

  Aws::Rails.add_action_mailer_delivery_method(
    :ses
  )
end
