namespace :accounts do
  namespace :oauth_apps do
    create_or_update_description = 'Create or update an oauth application in accounts, arguments USERNAME (application owner username), APP_NAME, REDIRECT_URI (separated by commas for multiple uris), EMAIL_FROM_ADDRESS, EMAIL_SUBJECT_PREFIX, TRUSTED (default true)'

    desc create_or_update_description
    task create_or_update: [:environment] do
      user = User.find_by_username(ENV['USERNAME'])
      name = ENV['APP_NAME']
      # one redirect uri per line
      redirect_uri = ENV['REDIRECT_URI'].try(:split, ',').try(:join, "\r\n")
      trusted = ENV['TRUSTED'].nil? || ENV['TRUSTED'].downcase == 'true'
      from_address = ENV['EMAIL_FROM_ADDRESS']
      subject_prefix = ENV['EMAIL_SUBJECT_PREFIX']

      ActiveRecord::Base.transaction do
        application = Doorkeeper::Application.find_or_initialize_by(name: name)
        application.redirect_uri = redirect_uri if redirect_uri.present?
        raise ArgumentError.new("User not found: #{ENV['USERNAME']}") \
          if application.owner.nil? && user.nil?
        unless user.nil? || application.owner.try(:has_owner?, user)
          group = Group.create
          group.add_owner(user)
          application.owner = group
        end
        application.trusted = trusted
        application.email_from_address = from_address if from_address.present?
        application.email_subject_prefix = subject_prefix if subject_prefix.present?
        action = application.new_record? ? 'Created' : 'Updated'
        application.save!
        puts "#{action} oauth application \"#{application.name}\""
      end
    end

    # The create and update tasks are aliases or create_or_update
    desc create_or_update_description
    task create: :create

    desc create_or_update_description
    task update: :create_or_update
  end
end
