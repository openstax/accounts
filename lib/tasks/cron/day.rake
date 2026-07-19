namespace :cron do
  task day: :log_to_stdout do
    Rails.logger.debug 'Starting daily cron'

    Rails.logger.info 'rake doorkeeper:cleanup'
    OpenStax::RescueFrom.this { Rake::Task['doorkeeper:cleanup'].invoke }

    Rails.logger.info 'UpdateSalesforceAssignableFields.call'
    OpenStax::RescueFrom.this { UpdateSalesforceAssignableFields.call }

    Rails.logger.info 'BookCatalogSync.call'
    OpenStax::RescueFrom.this { BookCatalogSync.call }

    Rails.logger.info 'Salesforce::AdoptionSync.call'
    OpenStax::RescueFrom.this { Salesforce::AdoptionSync.call }

    Rails.logger.info 'PushAdoptionReports.call_for_all_unpushed'
    OpenStax::RescueFrom.this { PushAdoptionReports.call_for_all_unpushed }

    Rails.logger.debug 'Finished daily cron'
  end
end
