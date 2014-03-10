require 'import_users'

namespace :accounts do
  desc 'Import users from csv file, CSV_FILE=csv_filename, output is in import_users_results.csv'
  task :import_users => [:environment] do
    ::ImportUsers.new(ENV['CSV_FILE']).read
  end
end
