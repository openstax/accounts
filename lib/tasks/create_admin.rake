namespace :accounts do
  desc 'Create an administrative user and/or set the password for said user'
  # Task specifically to create an administrative user and/or set the
  # password for said user. This task accepts to arguments, the username
  # and optionally a password. If the password is not supplied, the
  # username will be used for the password.
  task :create_admin, [:username, :password] => :environment do |t, args|
    ActiveRecord::Base.transaction do
      begin
        username = args[:username]
        password = args[:password] || args[:username]
        user = User.find_or_create_by_username(username)
        identity = Identity.find_or_create_by_user_id(user.id) do |identity|
          identity.password = password
          identity.password_confirmation = password
          identity.save!
        end
        user.is_administrator = true
        user.save!
        auth = Authentication.find_or_create_by_uid(user.identity.id.to_s) do |auth|
          auth.provider = 'identity'
          auth.user_id = user.id
          auth.save!
        end
      rescue Exception => e
        puts e
        raise ActiveRecord::Rollback
      end
    end
  end
end
