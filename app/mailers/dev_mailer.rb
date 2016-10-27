class DevMailer < SiteMailer

  def inspect_object(object:, to:, subject:)
    @object = object
    mail to: to,
         subject: subject
  end

end
