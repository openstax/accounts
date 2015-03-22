require 'csv'

class ImportUsers
  # Number of objects to create before creating a new transaction
  # (if the number is too big, it uses a lot of memory, if the number is too
  # small, it takes a long time)
  OBJECTS_PER_TRANSACTION = 1000

  def initialize(csv_file, app_id)
    @csv_file = csv_file
    @app_id = app_id
  end

  def read
    # Output results to import_users_results.{timestamp}.csv
    output_headers = [:row_number, :old_username, :new_username, :errors]
    CSV.open("import_users_results.#{Time.now.utc.iso8601}.csv", 'wb',
             headers: output_headers, write_headers: true) do |csv|

      csv_file_length = CSV.read(@csv_file, headers: true).length
      i = 0

      begin
        ActiveRecord::Base.transaction do
          CSV.foreach(@csv_file, headers: true) do |row|
            # line number is $. - 1 because there's a header line in the csv
            # file (line_num starts at 1)
            line_num = $. - 1

            # skip all the lines that don't belong to the current transaction
            next if (line_num - 1) / OBJECTS_PER_TRANSACTION != i

            # create the user for each line in the input csv file
            @user = nil
            username = nil
            error = nil
            begin
              username = row['username']
              create_user(username, row['password_digest'],
                          row['title'], row['first_name'], row['last_name'],
                          row['full_name'], row['email_address'])
              FindOrCreateApplicationUser.call(@app_id, @user.id) unless @app_id.nil?
            rescue ActiveRecord::RecordInvalid => e
              model_name = e.record.class.name
              error = "#{model_name} #{e.inspect}"
            rescue ActiveRecord::StatementInvalid => e
              error = e.inspect
            end

            if line_num % 100 == 0
              puts "Imported #{line_num} users..."
            end

            # output result
            csv << [row['row_number'], username, @user.try(:username), error]
          end

          # one transaction finished
          i += 1
        end

      # the import is done if we're looking for lines beyond the end of the
      # csv file
      end while OBJECTS_PER_TRANSACTION * i < csv_file_length
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
