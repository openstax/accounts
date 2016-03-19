require 'csv'  # for writing the results csv file
require 'smarter_csv'  # for more efficient reading of csv files

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

      chunk_index = 0
      SmarterCSV.process(@csv_file, chunk_size: OBJECTS_PER_TRANSACTION) do |chunk|
        ActiveRecord::Base.transaction do
          chunk.each_with_index do |row, index|
            # line_num starts from 1
            line_num = chunk_index * OBJECTS_PER_TRANSACTION + index + 1;

            # create the user for each line in the input csv file
            @user = nil
            username = nil
            error = nil
            begin
              username = row[:username] || ''
              create_user(username, row[:password_digest],
                          row[:title], row[:first_name], row[:last_name],
                          row[:email_address])
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
            csv << [row[:row_number], username, @user.try(:username), error]
          end
        end
        chunk_index += 1
      end
    end
  end

  def create_user(username, password_digest, title, first_name, last_name, email_address)
    @user = User.new
    @user.username = username
    @user.state = 'activated'
    @user.title = title
    @user.first_name = first_name
    @user.last_name = last_name
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
