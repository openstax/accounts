namespace :cron do
  task day: :log_to_stdout do
    Rails.logger.debug 'Starting daily cron'

    Rails.logger.info 'rake doorkeeper:cleanup'
    OpenStax::RescueFrom.this { Rake::Task['doorkeeper:cleanup'].invoke }

    Rails.logger.info 'UpdateSalesforceAssignableFields.call'
    OpenStax::RescueFrom.this { UpdateSalesforceAssignableFields.call }

    Rails.logger.info 'PushUserActivityToSalesforce.call'
    OpenStax::RescueFrom.this { PushUserActivityToSalesforce.call }

    Rails.logger.info 'SyncEducatorLeads.call'
    OpenStax::RescueFrom.this { SyncEducatorLeads.call }

    Rails.logger.debug 'Finished daily cron'
  end
end
