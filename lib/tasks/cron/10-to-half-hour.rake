namespace :cron do
  task '10-to-half-hour': :log_to_stdout do
    Rails.logger.debug 'Starting 10-to-half-hour cron'

    Rails.logger.info 'Queueing UpdateRejectedLeadsFromSalesforce'
    OpenStax::RescueFrom.this { UpdateRejectedLeadsFromSalesforce.call }

    Rails.logger.info 'Queueing UpdateSchoolSalesforceInfo'
    OpenStax::RescueFrom.this { UpdateSchoolSalesforceInfo.call }

    Rails.logger.debug 'Finished 10-to-half-hour cron'
  end
end
