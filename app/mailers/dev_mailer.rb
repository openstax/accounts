class DevMailer < ApplicationMailer

  default from: Rails.application.secrets.exception['sender'],
          to: Rails.application.secrets.exception['recipients']

  def inspect_object(object:, from: nil, to: nil, subject:)
    @object = object
    mail_params = {
      subject: "[Accounts] (#{Rails.application.secrets.environment_name}) #{subject}"
    }
    mail_params[:from] = from unless from.nil?
    mail_params[:to] = to unless to.nil?

    mail mail_params
  end

end
