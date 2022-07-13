# Copyright 2011-2016 Rice University. Licensed under the Affero General Public
# License version 3 or later.  See the COPYRIGHT file for details.

class ApplicationMailer < ActionMailer::Base
  default from: 'noreply@openstax.org'

  def mail(headers={}, &block)
    headers[:subject] = "[OpenStax] #{headers[:subject]}"

    super(headers, &block)
  end
end
