namespace :accounts do
  desc 'One-time repair: move educators who completed profile step 4 but were left stuck at ' \
       'incomplete_signup (a CompleteProfile bug) up to pending_faculty'
  # rake accounts:repair_profile_complete_faculty_status
  # DRY_RUN=true rake accounts:repair_profile_complete_faculty_status
  task repair_profile_complete_faculty_status: :environment do
    dry_run = ENV['DRY_RUN'] == 'true'
    counts = Hash.new(0)

    User.where.not(profile_completed_at: nil)
        .where(faculty_status: User::INCOMPLETE_SIGNUP)
        .where.not(role: User::STUDENT_ROLE)
        .find_each do |user|
      if dry_run
        counts[:repaired] += 1
        next
      end

      begin
        # Everything inside the lock is one transaction: the row is reloaded
        # before it is judged, and a failure after the advance rolls the advance
        # back so the user is still selected by a rerun.
        user.with_lock do
          next counts[:skipped] += 1 unless user.incomplete_signup?

          advanced = user.advance_faculty_status!(
            User::PENDING_FACULTY,
            source: :accounts,
            event_data: { reason: 'profile_completed_repair' }
          )
          next counts[:refused] += 1 unless advanced

          SecurityLog.create!(
            user: user,
            event_type: :faculty_status_repaired,
            event_data: {
              from: User::INCOMPLETE_SIGNUP,
              to: User::PENDING_FACULTY,
              reason: 'profile_completed_repair'
            }
          )
          Newflow::CreateOrUpdateSalesforceLead.perform_later(user: user)
          counts[:repaired] += 1
        end
      rescue StandardError => e
        counts[:failed] += 1
        Sentry.capture_exception(e, extra: { user_id: user.id })
      end
    end

    STDOUT.puts(dry_run ? 'DRY RUN -- no users changed.' : 'Done.')
    STDOUT.puts(
      "repaired: #{counts[:repaired]}, refused: #{counts[:refused]}, " \
      "skipped: #{counts[:skipped]}, failed: #{counts[:failed]}"
    )
  end
end
