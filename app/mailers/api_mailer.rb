# Copyright 2016 Rice University. Licensed under the Affero General Public
# License version 3 or later.  See the COPYRIGHT file for details.

class ApiMailer < ActionMailer::Base
  def mail(html_body, text_body, headers={})
    super(headers) do |format|
      format.html { render plain: html_body }
      format.text { render plain: text_body }
    end
  end
end
