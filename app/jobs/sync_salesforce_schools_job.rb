class SyncSalesforceSchoolsJob < ApplicationJob
  queue_as :salesforce_schools

  def perform(*args)
    OpenStax::RescueFrom.this { SyncSalesforceSchoolsJob.call }
  end
end
