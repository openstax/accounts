namespace :accounts do
  desc 'Create an administrative user and/or set the password for said user'
  # Task specifically to create an administrative user and/or set the
  # password for said user. This task accepts two arguments: the username,
  # and optionally a password. If the password is not supplied, the
  # username will be used for the password.
  task :create_admin, [:username, :password] => :environment do |t, args|
    ActiveRecord::Base.transaction do
      begin
        username = args[:username]
        password = args[:password] || args[:username]
        user = User.find_by(username: username) ||
               User.create(username: username, first_name: username, last_name: username)
        identity = Identity.find_or_create_by(user_id: user.id) do |identity|
          identity.user = user
          identity.password = password
          identity.password_confirmation = password
          identity.save!
        end
        user.is_administrator = true
        user.save!
        auth = Authentication.find_or_create_by(uid: user.identity.id.to_s) do |auth|
          auth.provider = 'identity'
          auth.user_id = user.id
          auth.save!
        end
        CreateEmailForUser['admin@openstax.org', user, {already_verified: true}]
      rescue Exception => e
        puts e
        raise ActiveRecord::Rollback
      end
    end
  end
end
