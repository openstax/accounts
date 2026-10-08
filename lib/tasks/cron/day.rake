namespace :cron do
  task day: :log_to_stdout do
    Rails.logger.debug 'Starting daily cron'

    cron_step('rake doorkeeper:cleanup') do
      Rake::Task['doorkeeper:cleanup'].invoke
    end

    cron_step('UpdateSalesforceAssignableFields.call') do
      UpdateSalesforceAssignableFields.call
    end

    cron_step('PushUserActivityToSalesforce.call') do
      PushUserActivityToSalesforce.call
    end

    cron_step('ForgetDeletedUsersInSalesforce.call') do
      ForgetDeletedUsersInSalesforce.call
    end

    cron_step('SyncEducatorLeads.call') do
      SyncEducatorLeads.call
    end

    Rails.logger.debug 'Finished daily cron'
  end
end
