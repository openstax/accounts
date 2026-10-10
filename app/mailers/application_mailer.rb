# Copyright 2011-2016 Rice University. Licensed under the Affero General Public
# License version 3 or later.  See the COPYRIGHT file for details.

class ApplicationMailer < ActionMailer::Base
  helper :application, :sessions

  default from: 'OpenStax Accounts <noreply@openstax.org>'

  # SES only returns InvalidParameterValue for a malformed request, so a retry can never succeed
  rescue_from Aws::SES::Errors::InvalidParameterValue do |e|
    @email_delivery&.advance!(:rejected, detail: "#{e.class}: #{e.message}")
    Sentry.capture_exception(
      e, level: :warning, extra: { mailer: self.class.name, action: action_name }
    )
  end

  protected

  def publish_ses_events_for(email_delivery)
    @email_delivery = email_delivery
    configuration_set = EmailDelivery.configuration_set
    return if email_delivery.nil? || configuration_set.nil?

    headers['X-SES-CONFIGURATION-SET'] = configuration_set
    headers['X-SES-MESSAGE-TAGS'] = {
      email_type: email_delivery.kind,
      email_delivery_id: email_delivery.id,
      accounts_env: EmailDelivery.environment_tag
    }.map { |name, value| "#{name}=#{value}" }.join(', ')
  end

  public

  def mail(headers={}, &block)
    headers[:subject] = "[OpenStax] #{headers[:subject]}"

    super(headers, &block)
  end
end
