require 'cgi'
require 'erb'

module DatabaseUrl
  # This method is not thread-safe. Do not call it after app initialization.
  def self.set_database_url
    return if ENV['BLAZER_DATABASE_URL']
    ENV['BLAZER_DATABASE_URL'] = config_to_url(db_config)
  end

  private
  def self.rails_loaded?
    const_defined?(:Rails)
  end

  def self.env
    return Rails.env if rails_loaded?
    ENV['RAILS_ENV'] || ENV['RACK_ENV']
  end

  def self.config_file
    File.expand_path('./config/database.yml')
  end

  def self.db_config
    config = YAML::load(ERB.new(IO.read(config_file)).result)
    config[env]
  end

  def self.config_to_url(config)
    query_values = {}
    query_values[:sslmode] = config['sslmode'] unless config['sslmode'].blank?
    query_values[:sslrootcert] = config['sslrootcert'] unless config['sslrootcert'].blank?
    query_values = nil if query_values.blank?
    Addressable::URI.new(
      scheme: config['adapter'],
      user: config['username'],
      password: config['password'],
      host: config['host'] || 'localhost',
      port: config['port'],
      path: config['database'],
      query_values: query_values
    ).to_s
  end
end

# This method is not thread-safe, but should be fine in an initializer.
DatabaseUrl.set_database_url
