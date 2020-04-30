namespace :accounts do
  desc 'Creates some users and stuff for demo-ing or testing Accounts'
  task :create_demo_data, [:how_many_users] => :environment do |t, args|
    args[:how_many_users].to_i.times do
      email_value = Faker::Internet.free_email

      # Do what `create_newflow_user` in the newflow feature helpers does...
      user = FactoryBot.create :user, :terms_agreed
      FactoryBot.create(:email_address, user: user, value: email_value, verified: true)
      identity = FactoryBot.create :identity, user: user, password: 'password'
      authentication = FactoryBot.create(:authentication, user: user, provider: 'identity', uid: identity.uid)

      puts("The email is #{email_value} and the password is 'password'")
    end
  end
end
