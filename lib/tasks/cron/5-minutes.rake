namespace :cron do
  task '5-minutes': :log_to_stdout do
    Rails.logger.debug 'Starting 5-minutes cron'

    cron_step('UpdateUserContactInfo.call') do
      UpdateUserContactInfo.call
    end

    Rails.logger.debug 'Finished 5-minutes cron'
  end
end
