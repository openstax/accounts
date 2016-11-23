module EnvUtilities
  def self.load_boolean(name:, default:)
    ENV.fetch(name, default).to_s == "true"
  end
end
