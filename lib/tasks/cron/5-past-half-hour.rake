namespace :cron do
  task '5-past-half-hour': :log_to_stdout do
    Rails.logger.debug 'Starting 5-past-half-hour cron'

    cron_step('UpdateSchoolSalesforceInfo.call') do
      UpdateSchoolSalesforceInfo.call
    end

    Rails.logger.debug 'Finished 5-past-half-hour cron'
  end
end
