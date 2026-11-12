namespace :accounts do
  desc "One-time backfill of users.which_books from Salesforce's Subject_Interest__c (Contact, else Lead)"
  # rake accounts:backfill_subject_interest
  # DRY_RUN=true rake accounts:backfill_subject_interest
  task backfill_subject_interest: :environment do
    dry_run = ENV['DRY_RUN'] == 'true'
    stats = BackfillSubjectInterest.call(dry_run: dry_run)
    puts "#{dry_run ? 'DRY RUN, nothing written. ' : ''}Done: #{stats.to_h}"
  end
end
