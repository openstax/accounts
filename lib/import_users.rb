require 'csv'

class ImportUsers
  def initialize(csv_file)
    @csv_file = csv_file
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
    CSV.open('import_users_results.csv', 'wb', headers: headers, write_headers: true) do |csv|
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
    @user = User.new(username: username)
    @user.is_temp = false
    @user.title = title
    @user.first_name = first_name
    @user.last_name = last_name
    @user.full_name = full_name
    @user.save!
    # Create a random password for validation
    identity = @user.create_identity!(password: SecureRandom.hex(8))
    # Import password hash which overwrites the password from previous step
    identity.update_attribute(:password_digest, password_digest)
    # User has to reset their password
    identity.password_expires_at = 1.day.ago
    identity.save!
    # User is using the omniauth identity authentication
    @user.authentications.create!(
      provider: 'identity',
      uid: identity.id.to_s,
    )
    # Imported email addresses are verified
    EmailAddress.create!(
      user_id: @user.id,
      value: email_address,
      verified: true,
    )
  end
end
