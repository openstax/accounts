require 'vcr'
require 'uri'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/cassettes'
  c.hook_into :webmock
  c.configure_rspec_metadata!
  c.allow_http_connections_when_no_cassette = false
  c.ignore_localhost = true
  # To avoid issues with the gem `webdrivers`, we must ignore the driver hosts
  # See https://github.com/titusfortner/webdrivers/wiki/Using-with-VCR-or-WebMock
  driver_hosts = Webdrivers::Common.subclasses.map { |driver| URI(driver.base_url).host }
  c.ignore_hosts(*driver_hosts)

  %w(
    tutor_specs_oauth_token
    tutor_specs_refresh_token
    tutor_specs_instance_url
  ).each do |salesforce_secret_name|
    Rails.application.secrets[:salesforce][salesforce_secret_name.to_sym].tap do |value|
      c.filter_sensitive_data("<#{salesforce_secret_name}>") { value } if value.present?
    end
  end
end

VCR_OPTS = {
  record: ENV.fetch('VCR_OPTS_RECORD', :none).to_sym, # This should default to :none
  allow_unused_http_interactions: false
}
