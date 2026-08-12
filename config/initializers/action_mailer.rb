ActiveSupport.on_load(:action_mailer) do
  # ActionMailer::DeliveryJob is the pre-Rails-6.0 legacy delivery job class,
  # removed entirely in Rails 7.0. This app has used the Rails 6.0+ default,
  # MailDeliveryJob, since `config.load_defaults 6.1`; this rescue_from was
  # registered on the unused legacy class the whole time.
  ActionMailer::MailDeliveryJob.rescue_from('AWS::SES::ResponseError') do |exception|
    # play it extra safe with `try` in case expection schema changes we don't explode within
    # an explosion.
    if exception.try(:response).try(:error).try(:[],'Code') == "InvalidParameterValue"
      # Will never succeed, so log/email the exception and don't reraise
      OpenStax::RescueFrom.do_not_reraise do
        OpenStax::RescueFrom.perform_rescue(exception)
      end
    else
      raise exception
    end
  end
end
