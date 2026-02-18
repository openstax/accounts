require 'posthog-ruby'

class OXPosthog
  def self.posthog
    @posthog ||= PostHog::Client.new(
      api_key: Rails.application.secrets.posthog_project_api_key,
      host: "https://us.i.posthog.com",
      on_error: Proc.new { |status, msg| Rails.logger.error("[PostHog] Error #{status}: #{msg}") },
      test_mode: Rails.env.test?,
    )
  end
end
