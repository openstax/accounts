class SyncSalesforceRejectedLeadsJob < ApplicationJob
  queue_as :salesforce_rejected_leads

  def perform(*args)
    OpenStax::RescueFrom.this { UpdateRejectedLeadsFromSalesforce.call }
  end
end
