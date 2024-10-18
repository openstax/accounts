ActiveSupport.on_load(:action_mailer) do
  ActionMailer::DeliveryJob.rescue_from('AWS::SES::ResponseError') do |exception|
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
