namespace :cron do
  task '10-to-half-hour': :log_to_stdout do
    Rails.logger.debug 'Starting 10-to-half-hour cron'

    Rails.logger.debug 'Finished 10-to-half-hour cron'
  end
end
