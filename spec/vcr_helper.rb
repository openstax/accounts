require 'vcr'
require 'uri'

VCR::Configuration.class_exec do
  def filter_secret(path_to_secret)
    secret_name = path_to_secret.join("_")

    secret_value = Rails.application.secrets
    path_to_secret.each do |key|
      secret_value = secret_value[key.to_sym]
    end
    secret_value = secret_value.to_s

    if secret_value.present?
      filter_sensitive_data("<#{secret_name}>") { secret_value }

      # If the secret value is a URL, it may be used without its protocol
      if secret_value.starts_with?("http")
        secret_value_without_protocol = secret_value.sub(/^https?\:\/\//,'')
        filter_sensitive_data("<#{secret_name}_without_protocol>") do
          secret_value_without_protocol
        end
      end


      # If the secret value is inside a URL, it will be URL encoded which means it
      # may be different from value.  Handle this.
      url_secret_value = CGI::escape(secret_value.to_s)
      if secret_value != url_secret_value
        filter_sensitive_data("<#{secret_name}_url>") { url_secret_value }
      end
    end
  end
end

VCR.configure do |c|
  c.cassette_library_dir = 'spec/cassettes'
  c.hook_into :webmock
  c.configure_rspec_metadata!
  c.allow_http_connections_when_no_cassette = false
  c.ignore_localhost = true

  # The recorded cassettes cannot match on accounts_uuid in Salesforce because it changes each time FactoryBot creates a user.
  # The responses from Salesforce otherwise are the same.
  c.default_cassette_options = {
    :match_requests_on => [:method,
                           VCR.request_matchers.uri_without_param(:accounts_uuid_c__c)]
  }

  if in_docker?
    # Within docker, localhost can be different so add it here explicitly; also add
    # 'chrome' for selenium via docker
    c.ignore_hosts(IPSocket.getaddress(Socket.gethostname), "chrome")
  else
    require 'webdrivers'
    # To avoid issues with the gem `webdrivers`, we must ignore the driver hosts
    # See https://github.com/titusfortner/webdrivers/wiki/Using-with-VCR-or-WebMock
    driver_hosts = Webdrivers::Common.subclasses.map { |driver| URI(driver.base_url).host }
    c.ignore_hosts(*driver_hosts)
  end

  %w(
    instance_url
    username
    password
    security_token
    consumer_key
    consumer_secret
  ).each { |salesforce_secret_name| c.filter_secret(['salesforce', salesforce_secret_name]) }

  %w(
    ip_api_key
    sheerid_api_secret
  ).each { |secret_name| c.filter_secret([secret_name]) }
end

VCR_OPTS = {
  record: ENV.fetch('VCR_OPTS_RECORD', :none).to_sym, # This should default to :none
  allow_unused_http_interactions: false
}
