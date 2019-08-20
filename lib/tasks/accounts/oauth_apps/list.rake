namespace :accounts do
  namespace :oauth_apps do
    desc 'List tokens and secrets for all the oauth applications in accounts, optional argument APP_NAME'
    task list: [:environment] do
      app_name = "#{ENV['APP_NAME']}".downcase
      apps = Doorkeeper::Application.select('name, uid, secret').order(:name)
      apps = apps.where.has { |t| t.name.lower == app_name } if app_name.present?

      result = []
      apps.each do |row|
        result << {
          'name'   => row.name,
          'uid'    => row.uid,
          'secret' => row.secret,
        }
      end

      if result.empty?
        puts 'No applications found.' if apps.empty?
        next
      end

      output = ENV.fetch('OUTPUT', '').downcase
      if output.eql? 'yaml'
        puts result.to_yaml
      elsif output.eql? 'json'
        puts result.to_json
      else
        result.each { |o| puts "#{o['name']}: #{o['uid']} #{o['secret']}" }
      end
    end
  end
end
