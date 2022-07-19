namespace :accounts do
  desc 'Create leads for faculty users that started signup but did not finish so they can be reviewed by customer service'
  # Run task with the optional days of leads you want uploaded eg. `rake accounts:create_leads_for_abandoned_user_signups[1]`
  # Defaults to two days, with the idea being to run it once per day, allowing it to catch any it might have missed while processing.
  task :create_leads_for_abandoned_user_signups, [:day] => [:environment] do |t, args|
    args.with_defaults(:day => 2)
    puts(args[:day].to_i)
    users = User.where(state: 'unverified').where("created_at >= ?", args[:day].to_i.day.ago)
    puts users
    users.each { |user|
      user.faculty_status = :incomplete_signup
      user.save!
      CreateSalesforceLead.perform_later(user.id)
    }
  end
end
