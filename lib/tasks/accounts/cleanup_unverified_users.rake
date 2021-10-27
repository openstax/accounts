namespace :accounts do
  desc 'Cleanup accounts that have unverified email addresses for over one year'
  task :cleanup_unverified_users => :environment do
    User.cleanup_unverified_users
  end
end
