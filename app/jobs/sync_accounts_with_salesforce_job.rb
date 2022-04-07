class SyncAccountsWithSalesforceJob < ApplicationJob
  queue_as :salesforce_accounts

  def perform(*args)
    OpenStax::RescueFrom.this { SyncUserAccountsWithSalesforce.call }
  end
end
