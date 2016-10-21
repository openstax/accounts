class DevMailer < SiteMailer

  def pp(object:, to:, subject:)
    @object = object
    mail to: to,
         subject: subject
  end

end
