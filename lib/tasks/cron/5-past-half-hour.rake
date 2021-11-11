namespace :cron do
  task '5-past-half-hour': :log_to_stdout do
    Rails.logger.debug 'Starting 5-past-half-hour cron'

    allow_error_email = Time.zone.now.hour == 0 && Time.zone.now.min < 10
    Rails.logger.info "UpdateUserSalesforceInfo.call allow_error_email: #{allow_error_email}"
    OpenStax::RescueFrom.this { UpdateUserSalesforceInfo.call allow_error_email: allow_error_email }

    Rails.logger.debug 'Finished 5-past-half-hour cron'
  end
end
