require_relative 'rails_helper'

require 'vcr'

VCR::Configuration.class_exec do
  def filter_secret(path_to_secret)
    secret_name = path_to_secret.join('_')

    secret_value = Rails.application.secrets
    path_to_secret.each { |key| secret_value = secret_value&.[](key.to_sym) }

    if secret_value.present?
      secret_value = secret_value.to_s
      filter_sensitive_data("<#{secret_name}>") { secret_value }

      # If the secret value is a URL, it may be used without its protocol
      if secret_value.to_s.starts_with?('http')
        secret_value_without_protocol = secret_value.sub(/^https?\:\/\//, '')
        filter_sensitive_data("<#{secret_name}_without_protocol>") do
          secret_value_without_protocol
        end
      end

      # If the secret value is inside a URL, it will be URL encoded which means it
      # may be different from value. Handle this.
      url_secret_value = CGI::escape(secret_value)
      if secret_value != url_secret_value
        filter_sensitive_data("<#{secret_name}_url>") { url_secret_value }
      end
    end
  end

  # Reference: https://github.com/vcr/vcr/blob/master/lib/vcr/configuration.rb#L225
  def filter_request_header(header, tag = nil)
    before_record(tag) do |interaction|
      (interaction.request.headers[header] || []).each_with_index do |orig_text, index|
        placeholder = "<#{header} #{index + 1}>"
        log "before_record: replacing #{orig_text.inspect} with #{placeholder.inspect}"
        interaction.filter!(orig_text, placeholder)
      end
    end

    before_playback(tag) do |interaction|
      (interaction.request.headers[header] || []).each_with_index do |orig_text, index|
        placeholder = "<#{header} #{index + 1}>"
        log "before_playback: replacing #{orig_text.inspect} with #{placeholder.inspect}"
        interaction.filter!(placeholder, orig_text)
      end
    end
  end

  def filter_response_header(header, tag = nil)
    before_record(tag) do |interaction|
      (interaction.response.headers[header] || []).each_with_index do |orig_text, index|
        placeholder = "<#{header} #{index + 1}>"
        log "before_record: replacing #{orig_text.inspect} with #{placeholder.inspect}"
        interaction.filter!(orig_text, placeholder)
      end
    end

    before_playback(tag) do |interaction|
      (interaction.response.headers[header] || []).each_with_index do |orig_text, index|
        placeholder = "<#{header} #{index + 1}>"
        log "before_playback: replacing #{orig_text.inspect} with #{placeholder.inspect}"
        interaction.filter!(placeholder, orig_text)
      end
    end
  end
end

VCR.configure do |c|
  c.cassette_library_dir = 'spec/cassettes'
  c.hook_into :webmock
  c.configure_rspec_metadata!
  c.allow_http_connections_when_no_cassette = false
  c.ignore_localhost                        = true
  c.ignore_request { |request| Addressable::URI.parse(request.uri).path == '/oauth/token' }
  c.preserve_exact_body_bytes { |http_message| !http_message.body.valid_encoding? }

  # Turn on debug logging, works in Travis too tho in full runs results
  # in Travis build logs that are too large and cause a Travis error
  # c.debug_logger = $stderr

  %w(
    instance_url
    username
    password
    security_token
    consumer_key
    consumer_secret
  ).each do |field_name|
    c.filter_secret ['salesforce', field_name]
  end

  %w(
    sheerid_api_secret
  ).each do |field_name|
    c.filter_secret(['sheerid', field_name])
  end
end

VCR_OPTS = {
  # This should default to :none
  record: ENV.fetch('VCR_OPTS_RECORD', :none).to_sym,
  allow_unused_http_interactions: false
}
