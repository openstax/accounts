namespace :accounts do
  namespace :oauth_apps do
    desc 'List tokens and secrets for all the oauth applications in accounts, optional argument APP_NAME'
    task list: [:environment] do
      app_name = "#{ENV['APP_NAME']}".downcase
      if app_name.present?
        apps = Doorkeeper::Application.where { lower(name) == app_name }
      else
        apps = Doorkeeper::Application
      end
      apps = apps.order(:name)
      apps.each do |application|
        puts "#{application.name}: #{application.uid} #{application.secret}"
      end
      puts 'No applications found.' if apps.empty?
    end
  end
end
