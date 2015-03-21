require 'csv'

class ImportUsers
  def initialize(csv_file, app_id)
    @csv_file = csv_file
    @app_id = app_id
  end

  def read
    result = {}
    CSV.foreach(@csv_file, headers: true) do |row|
      @user = nil
      username = nil
      begin
        username = row['username']
        result[username] = {row_number: row['row_number']}
        create_user(username, row['password_digest'],
                    row['title'], row['first_name'], row['last_name'],
                    row['full_name'], row['email_address'])
        FindOrCreateApplicationUser.call(@app_id, @user.id) unless @app_id.nil?
      rescue ActiveRecord::RecordInvalid => e
        model_name = e.record.class.name
        result[username].update({error: "#{model_name} #{e.inspect}"})
      end
      result[username].update({user: @user}) unless @user.nil?
      if ($. - 1) % 10 == 0
        puts "Imported #{$. - 1} users..."
      end
    end

    headers = [:row_number, :old_username, :new_username, :errors]
    CSV.open("import_users_results.#{Time.now.utc.iso8601}.csv", 'wb', headers: headers, write_headers: true) do |csv|
      result.each do |old_username, value|
        row_number = value[:row_number]
        user = value[:user] || ''
        error = value[:error] || ''
        csv << [row_number, old_username, user.try(:username), error]
      end
    end
  end

  def create_user(username, password_digest, title, first_name, last_name, full_name, email_address)
    person = Person.create!
    @user = User.new
    @user.username = username
    @user.is_temp = false
    @user.title = title
    @user.first_name = first_name
    @user.last_name = last_name
    @user.full_name = full_name
    @user.save!(:validate => false)

    identity = @user.build_identity
    # Import password hash
    identity.password_digest = password_digest
    # User has to reset their password
    identity.password_expires_at = DateTime.now
    # Skip password validation
    identity.save!(validate: false)

    # User is using the omniauth identity authentication
    @user.authentications.create!(
      provider: 'identity',
      uid: identity.id.to_s,
    )

    # Imported email addresses are verified
    ea = EmailAddress.new(value: email_address)
    ea.user = @user
    ea.verified = true
    ea.save!
  end
end
