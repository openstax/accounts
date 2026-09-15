namespace :accounts do
  desc 'One-time backfill matching existing Salesforce Student__c records to Accounts users by uuid'
  # rake accounts:reconcile_salesforce_student_ids
  task reconcile_salesforce_student_ids: :environment do
    stats = ReconcileSalesforceStudentIds.call
    STDOUT.puts "Done: #{stats.to_h}"
  end
end
