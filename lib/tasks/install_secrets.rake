require 'aws-sdk-ssm'

desc <<-DESC.strip_heredoc
  Pull the secrets for this environment and application from the AWS Parameter
  Store and use them to write the secrets.yml
DESC
task :install_secrets, [] do
  # Load the system-wide and local env vars here since the Rails application isn't loaded
  # for this rake task
  Dotenv.load('/etc/.env', '.env')

  # Secrets live in the AWS Parameter Store under a /env_name/parameter_namespace/
  # hierarchy.  Several environment variables are set by the AWS cloudformation scripts.
  #
  # This script would take the following Parameter Store values:
  #
  #   /qa/interactions/secret_key = 123456
  #   /qa/interactions/redis/namespace = interactions-dev
  #
  # and (over)write the following to config/secrets.yml:
  #
  #   production:
  #     secret_key: 123456
  #     redis:
  #       namespace: interactions-dev

  region = get_env_var!('REGION')
  env_name = get_env_var!('ENV_NAME')
  namespace = get_env_var!('SECRETS_NAMESPACE')

  secrets = HashWithIndifferentAccess.new

  # When we get parameters from the store, we want to ignore the env_name
  # and the parameter namespace.  Calculate how many levels there are here
  num_ignored_key_levels = [env_name, namespace].join('/').split('/').count

  client = Aws::SSM::Client.new(region: region)
  client.get_parameters_by_path({path: "/#{env_name}/#{namespace}/",
                                 recursive: true,
                                 with_decryption: true}).each do |response|
    response.parameters.each do |parameter|
      # break out the flattened keys and ignore the env name and namespace
      keys = parameter.name.split('/').reject(&:blank?)[num_ignored_key_levels..-1]
      value = parameter.type == "StringList" ? parameter.value.split(",") : parameter.value
      deep_populate(secrets, keys, cast_to_number_if_number(value))
    end
  end

  database_secrets = secrets.delete(:database)
  write_yaml_file("config/database.yml", {
    production: {
      database: database_secrets[:name],
      host: database_secrets[:url],
      port: database_secrets[:port],
      username: database_secrets[:username],
      password: database_secrets[:password],
      adapter: "postgresql",
      encoding: "unicode",
      pool: '<%= ENV.fetch("RAILS_MAX_THREADS") { 10 } %>'
    }
  })

  scout_secrets = secrets.delete('scout')
  write_yaml_file("config/scout_apm.yml", {
    production: {
      key: scout_secrets[:license_key],
      name: "accounts (#{env_name})",
      # crude way to disable scout by environment
      monitor: !/noscout/.match?(env_name),
      ignore: %w(/ping)
    }
  })

  secrets[:loadtesting_active] = (/loadtesting/.match?(env_name)).to_s
  secrets[:sso_signature_public_key] = :sso_signature_private_key.public_key

  write_yaml_file("config/secrets.yml", {
    production: secrets
  })
end

def write_yaml_file(filename, hash)
  File.open(File.expand_path(filename), "w") do |file|
    # write the hash as yaml, getting rid of the "---\n" at the front
    file.write(hash.deep_stringify_keys.to_yaml[4..-1])
  end
end

def get_env_var!(name)
  ENV[name].tap do |value|
    raise "Environment variable #{name} isn't set!" if value.nil?
  end
end

def deep_populate(hash, keys, value)
  if keys.length == 1
    hash[keys[0]] = value
  else
    hash[keys[0]] ||= {}
    deep_populate(hash[keys[0]], keys[1..-1], value)
  end
end

def cast_to_number_if_number(string_or_array)
  if string_or_array.is_a?(Array)
    string_or_array.map{|string| cast_to_number_if_number(string)}
  else
    string = string_or_array
    if /\A[+-]?\d+(\.[\d]+)?\z/.match(string)
       (string.to_f % 1) > 0 ? string.to_f : string.to_i
    else
      string
    end
  end
end
