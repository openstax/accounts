namespace :accounts do
  desc 'One-time backfill matching students self-reported school text to a School'
  # rake accounts:match_student_self_reported_schools
  # DRY_RUN=true rake accounts:match_student_self_reported_schools
  task match_student_self_reported_schools: :environment do
    stats = MatchStudentSelfReportedSchools.call(dry_run: ENV['DRY_RUN'] == 'true')
    STDOUT.puts "Done: #{stats.to_h}"
  end
end
