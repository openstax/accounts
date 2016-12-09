class DevMailer < SiteMailer

  def inspect_object(object:, to: nil, subject:)
    @object = object
    mail to: to || Rails.application.secrets.exception['recipients'],
         subject: subject
  end

end
