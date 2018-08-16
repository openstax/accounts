# Copyright 2011-2016 Rice University. Licensed under the Affero General Public
# License version 3 or later.  See the COPYRIGHT file for details.

class ApplicationMailer < ActionMailer::Base
  helper :application, :sessions

  default from: 'noreply@openstax.org'

  def mail(headers={}, &block)
    headers[:subject] = "#{headers[:subject]}"

    super(headers, &block)
  end
end
