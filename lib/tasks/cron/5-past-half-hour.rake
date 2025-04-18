namespace :cron do
  task '5-past-half-hour': :log_to_stdout do
    Rails.logger.debug 'Starting 5-past-half-hour cron'

    Rails.logger.info "Starting Salesforce Contact and School Sync"
    OpenStax::RescueFrom.this { UpdateSchoolSalesforceInfo.call }
    OpenStax::RescueFrom.this { UpdateUserContactInfo.call }

    Rails.logger.debug 'Finished 5-past-half-hour cron'
  end
end
