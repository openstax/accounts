namespace :cron do
  task '5-minutes': :log_to_stdout do
    Rails.logger.debug 'Starting 5-minutes cron'

    Rails.logger.info 'UpdateUserContactInfo.call'
    OpenStax::RescueFrom.this { UpdateUserContactInfo.call }

    Rails.logger.debug 'Finished 5-minutes cron'
  end
end
