require 'doorkeeper/models/active_record/application'

namespace :accounts do
  namespace :ost do
    # These are the apps that we want to create
    app_data = [{:name => "Openstax Exercises", :prefix => "exercises"},
                {:name => "Openstax Tutor", :prefix => "tutor"},
                {:name => "Openstax Exchange", :prefix => "exchange"},
                {:name => "Openstax Biglearn", :prefix => "biglearn"}]
    desc "Manage applications for exercises, exchange, tutor and biglearn"
    task :create_apps, [:app_domain_suffix, :admin_password] => :environment do |t, args|
      ActiveRecord::Base.transaction do
        begin
          # Get the application url suffix if provided
          suffix = args[:app_domain_suffix] || ''
          # Get the admin password
          password = args[:admin_password]
          # Create application owner if needed
          app_owner_group = Group.find_or_create_by_name('ost_app_admin_group')
          user = User.find_or_create_by_username('ost_app_admin') do |new_user|
            new_user.identity = Identity.create do |identity|
              identity.password = password
              identity.password_confirmation = password
              identity.user_id = user.id
            end
            new_user.identity.save!
            app_owner_group.add_owner(user)
          end
          auth = Authentication.find_or_create_by_uid(user.identity.id.to_s) do |new_auth|
            new_auth.provider = 'identity'
            new_auth.user_id = user.id
            new_auth.save!
          end
          # For each app above, create and assign defaults if it doesn't exist
          app_data.each do |app|
            url = "https://#{app[:prefix]}#{suffix}.openstax.org/accounts/auth/openstax/callback"
            Doorkeeper::Application.find_or_create_by_name(app[:name]) do |application|
              application.redirect_uri = url
              application.owner = app_owner_group
              application.trusted = true
              application.email_from_address = "noreply@#{app[:prefix]}.openstax.org"
              application.email_subject_prefix = "[#{app[:name]}]"
              application.save!
              puts "Created #{app[:name]} with return url @ #{url}"
            end
          end
        rescue Exception => e
          puts e
          raise ActiveRecord::Rollback
        end
      end
    end
    task :get_app_info => :environment do
      apps = Doorkeeper::Application.where(:name => app_data.map { |app| app[:name] })
      apps = apps.map { |app|  {:name => app.name,
                                :id => app.uid,
                                :secret => app.secret,
                                :url =>  app.redirect_uri}}
      puts JSON.generate(apps)
    end
  end
end
