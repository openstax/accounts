require "erb"

module DatabaseUrl
  def self.set_database_url
    return if ENV["DATABASE_URL"]
    ENV["DATABASE_URL"] = config_to_url(db_config)
  end

  private
  def self.rails_loaded?
    const_defined?(:Rails)
  end

  def self.env
    return Rails.env if rails_loaded?
    ENV["RAILS_ENV"] || ENV["RACK_ENV"]
  end

  def self.config_file
    File.expand_path("./config/database.yml")
  end

  def self.db_config
    config = YAML::load(ERB.new(IO.read(config_file)).result)
    config[env]
  end

  def self.config_to_url(config)
    if config["username"] || config["password"]
      user_info = [ config["username"], config["password"] ].join(":")
    else
      user_info = nil
    end
    URI::Generic.new(config["adapter"],
                     user_info,
                     config["hostname"] || "localhost",
                     config["port"],
                     nil,
                     "/#{config["database"]}",
                     nil,
                     nil,
                     nil).to_s
  end
end
DatabaseUrl.set_database_url
