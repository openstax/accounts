namespace :cron do
  task '5-past-half-hour': :log_to_stdout do
    Rails.logger.debug 'Starting 5-past-half-hour cron'

    Rails.logger.debug 'Starting SyncSalesforceContactsJob'
    SyncSalesforceContactsJob.perform_later()

    Rails.logger.debug 'Starting SyncAccountsWithSalesforceJob'
    SyncAccountsWithSalesforceJob.perform_later()

    Rails.logger.debug 'Finished 5-past-half-hour cron'
  end
end
