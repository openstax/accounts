require 'cgi'
require 'erb'

module DatabaseUrl
  def self.get_database_url
    config_to_url(db_config)
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
    # Psych 4 (default since Ruby 3.1) disallows YAML aliases in the plain
    # `load`/`safe_load` path, and database.yml relies on `<<: *default`
    # merge aliases. Rails' own YAML loading was updated for this when we
    # moved to Rails 7, but this file parses database.yml itself, so it
    # needs the same unsafe_load treatment.
    config = YAML.unsafe_load(ERB.new(File.read(config_file)).result)
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

ENV['BLAZER_DATABASE_URL'] ||= DatabaseUrl.get_database_url
