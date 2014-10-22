require 'import_users'

namespace :accounts do
  desc 'Import users from csv file, CSV_FILE=csv_filename, APP_ID=app_id, output is in import_users_results.csv'
  task :import_users => [:environment] do
    # if APP_ID is not an integer, an Argument Error will be raised here
    app_id = Integer(ENV['APP_ID']) unless ENV['APP_ID'].nil?
    ::ImportUsers.new(ENV['CSV_FILE'], app_id).read
  end
end
