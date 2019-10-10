# The rake tasks in this module are used to manage trusted OpenStax
# oauth applications.  Currently, Exercises, Tutor, Exchange and
# Biglearn oauth applications are managed by these tasks.

namespace :accounts do
  namespace :ost do
    # These are the apps that we want to create
    app_data = [
      {
        name: "OpenStax Exercises",
        prefix: "exercises"
      },
      {
        name: "OpenStax Tutor",
        prefix: "tutor",
        skip_terms: true,
        extra_redirect_paths: [
          "signup"
        ]
      },
      {
        name: "OpenStax Exchange",
        prefix: "exchange"
      },
      {
        name: "OpenStax BigLearn",
        prefix: "biglearn"
      }
    ]
    desc "Manage applications for exercises, exchange, tutor and biglearn"

    # This task creates applications based on the given parameters.
    # This task creates an user with the username `ost_app_admin` with
    # the given password if one is not found already.  It also creates
    # a group `ost_app_admin_group` and assigns the newly created user
    # to that group.  Once the user and the group are setup, it
    # creates each of the applications declared above.
    task :create_apps, [:app_domain_suffix, :admin_password] => :environment do |t, args|

      ActiveRecord::Base.transaction do
        begin
          # Get the application url suffix if provided
          suffix = args[:app_domain_suffix] || ''
          # Get the admin password
          password = args[:admin_password]
          # Create application owner if needed
          app_owner_group = Group.find_or_create_by(name: 'ost_app_admin_group')
          user = User.find_or_create_by(username: 'ost_app_admin')
          identity = Identity.find_or_create_by(user_id: user.id) do |new_identity|
            new_identity.password = password
            new_identity.password_confirmation = password
            new_identity.user = user
            new_identity.save!
          end
          app_owner_group.add_owner(user)
          auth = Authentication.find_or_create_by(uid: user.identity.id.to_s) do |new_auth|
            new_auth.provider = 'identity'
            new_auth.user_id = user.id
            new_auth.save!
          end

          # For each app above, create and assign defaults if it doesn't exist
          app_data.each do |app|
            # If the suffix parameter starts with `http` assume that
            # the entire hostname is given with a placeholder for the
            # app name (`<app>`).  Otherwise use the default url
            # pattern to construct the redirect url.
            redirect_paths = (app[:extra_redirect_paths] || []).unshift("accounts/auth/openstax/callback")

            redirect_url_base = suffix.start_with?('http') ?
                                  "#{suffix.gsub('<app>', app[:prefix])}/" :
                                  "https://#{app[:prefix]}#{suffix}.openstax.org/"

            redirect_urls = redirect_paths.map{|path| "#{redirect_url_base}#{path}"}.join("\n")

            Doorkeeper::Application.find_or_create_by(name: app[:name]) do |application|
              application.redirect_uri = redirect_urls
              application.owner = app_owner_group
              application.can_access_private_user_data = true
              application.can_find_or_create_accounts = true
              application.can_message_users = true
              application.can_skip_oauth_screen = true
              application.email_from_address = "noreply@#{app[:prefix]}.openstax.org"
              application.email_subject_prefix = "[#{app[:name]}]"
              application.skip_terms = app[:skip_terms] || false
              application.save!
              puts "Created #{app[:name]} with return url @ #{redirect_urls.split("\n").first}"
            end
          end
        rescue Exception => e
          puts e
          raise ActiveRecord::Rollback
        end
      end
    end

    # This task gets information about all the authorized oauth
    # applications.  For each application found, it returns the
    # application id and secret as a JSON object list.
    task get_app_info: :environment do

      apps = Doorkeeper::Application.where(name: app_data.map { |app| app[:name] })
      apps = apps.map { |app|  {name: app.name,
                                id: app.uid,
                                secret: app.secret,
                                url: app.redirect_uri}}
      puts JSON.generate(apps)
    end
  end
end
