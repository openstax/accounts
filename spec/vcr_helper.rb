require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/cassettes'
  c.hook_into :webmock
  c.configure_rspec_metadata!
  c.allow_http_connections_when_no_cassette = false
  c.ignore_localhost = true

  %w(
    tutor_specs_oauth_token
    tutor_specs_refresh_token
    tutor_specs_instance_url
  ).each do |salesforce_secret_name|
    Rails.application.secrets['salesforce'][salesforce_secret_name].tap do |value|
      c.filter_sensitive_data("<#{salesforce_secret_name}>") { value } if value.present?
    end
  end
end

VCR_OPTS = {
  record: ENV["VCR_OPTS_RECORD"].try(:to_sym) || :none, # This should default to :none before pushing
  allow_unused_http_interactions: false
}
