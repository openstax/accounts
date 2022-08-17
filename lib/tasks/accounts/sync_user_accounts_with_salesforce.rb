namespace :accounts do
  desc 'Sync the OpenStax Account custom object with Salesforce'
  # rake accounts:sync_accounts_with_salesforce
  task :sync_accounts_with_salesforce, [:day] => [:environment] do |t, args|
    users = User.where.not(salesforce_contact_id: nil, salesforce_lead_id: nil)
    users.each { |user|
      AddAccountToSalesforceJob.perform_later(user.id)
    }
  end
end
