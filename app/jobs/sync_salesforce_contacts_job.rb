class SyncSalesforceContactsJob < ApplicationJob
  queue_as :salesforce_contacts

  def perform(*args)
    OpenStax::RescueFrom.this { UpdateUserContactInfo.call }
  end
end
