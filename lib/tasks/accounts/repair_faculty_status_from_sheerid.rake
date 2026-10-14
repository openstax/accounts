namespace :accounts do
  desc 'One-time repair: recompute faculty_status from each user\'s SheerID verification'
  # rake accounts:repair_faculty_status_from_sheerid
  # DRY_RUN=true rake accounts:repair_faculty_status_from_sheerid
  task repair_faculty_status_from_sheerid: :environment do
    dry_run = ENV['DRY_RUN'] == 'true'
    counts = Hash.new(0)

    User.where.not(sheerid_verification_id: nil).find_each do |user|
      verification = user.sheerid_verification
      next if verification.nil?

      old_status = user.faculty_status
      new_status = verification.faculty_status_for_step.to_s

      if dry_run
        allowed = FacultyStatusLadder.allowed?(from: old_status, to: new_status, source: :accounts)
        counts["#{old_status} -> #{new_status}"] += 1 if allowed && old_status != new_status
        next
      end

      advanced = user.advance_faculty_status!(
        new_status, source: :accounts, event_data: { repair: true }
      )
      next unless advanced

      new_status = user.faculty_status
      next if new_status == old_status

      counts["#{old_status} -> #{new_status}"] += 1

      SecurityLog.create!(
        user: user,
        event_type: :faculty_status_repaired,
        event_data: { from: old_status, to: new_status }
      )
      Newflow::CreateOrUpdateSalesforceLead.perform_later(user: user)
    end

    STDOUT.puts(dry_run ? 'DRY RUN -- no changes made.' : 'Done.')
    counts.sort.each { |transition, count| STDOUT.puts "#{transition}: #{count}" }
  end
end
