if Rails.env.production?
  secrets = Rails.application.secrets[:aws][:ses]

  ActionMailer::Base.add_delivery_method(
    :ses,
    AWS::SES::Base,
    access_key_id:     secrets[:access_key_id],
    secret_access_key: secrets[:secret_access_key],
    server:            secrets[:endpoint_server]
  )
end
