require 'import_users'

namespace :accounts do
  desc 'Import users from csv file, CSV_FILE=csv_filename, APP_NAME=app_name, output is in import_users_results.csv'
  task :import_users => [:environment] do
    apps = {}
    Doorkeeper::Application.find_each do |app|
      apps[app.name] = { id: app.id, callback: app.redirect_uri }
    end
    app = apps[ENV['APP_NAME']]

    if app.nil?
      puts "Cannot find \"#{ENV['APP_NAME']}\".  Here is a list of apps:"
      apps.each do |app_name, app|
        puts("app name: %-20s callback: %s" % [app_name, app[:callback]])
      end
      raise "APP_NAME \"#{ENV['APP_NAME']}\" not found"
    end

    app_id = app[:id]
    ::ImportUsers.new(ENV['CSV_FILE'], app_id).read
  end
end
