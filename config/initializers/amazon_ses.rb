ActionMailer::Base.add_delivery_method :ses, AWS::SES::Base,
  :access_key_id     => SECRET_SETTINGS[:aws_ses_access_key_id],
  :secret_access_key => SECRET_SETTINGS[:aws_ses_secret_access_key],
  :server => 'email.us-east-1.amazonaws.com'