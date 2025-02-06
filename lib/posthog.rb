require 'posthog-ruby'

class OXPosthog
  def self.posthog
    @posthog = PostHog::Client.new(
      api_key: Rails.application.secrets.posthog_project_api_key,
      host: "https://us.i.posthog.com",
      on_error: Proc.new { |status, msg| print msg },
      disabled: Rails.env.test?,
      async: true,
    )
  end
end
