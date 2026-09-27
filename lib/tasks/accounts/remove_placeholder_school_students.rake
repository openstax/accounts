namespace :accounts do
  desc 'One-time cleanup removing Student__c records pass 1 created for placeholder-school students'
  # rake accounts:remove_placeholder_school_students
  # DRY_RUN=true rake accounts:remove_placeholder_school_students
  task remove_placeholder_school_students: :environment do
    stats = RemovePlaceholderSchoolStudents.call(dry_run: ENV['DRY_RUN'] == 'true')
    STDOUT.puts "Done: #{stats.to_h}"
  end
end
