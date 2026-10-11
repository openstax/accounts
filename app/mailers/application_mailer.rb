# Copyright 2011-2016 Rice University. Licensed under the Affero General Public
# License version 3 or later.  See the COPYRIGHT file for details.

class ApplicationMailer < ActionMailer::Base
  helper :application, :sessions

  default from: 'OpenStax Accounts <noreply@openstax.org>'

  # SES only returns InvalidParameterValue for a malformed request, so a retry can never succeed
  rescue_from Aws::SES::Errors::InvalidParameterValue do |e|
    Sentry.capture_exception(
      e, level: :warning, extra: { mailer: self.class.name, action: action_name }
    )
  end

  def mail(headers={}, &block)
    headers[:subject] = "[OpenStax] #{headers[:subject]}"

    super(headers, &block)
  end
end
