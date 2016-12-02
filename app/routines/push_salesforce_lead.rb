class PushSalesforceLead

  lev_routine

  protected

  def exec(user:, role:, phone_number:, school:, num_students:, using_openstax:, url:, newsletter:, subject:)

    status.set_job_name(self.class.name)
    status.set_job_args(user: user.to_global_id.to_s)

    # Get email with try -- should be there, but who knows
    email = user.contact_infos.verified.first.try(:value)

    source = (role || "").match(/instructor/i) ? "OSC Faculty" : "OSC User"

    lead = Salesforce::Lead.new(
      first_name: user.first_name,
      last_name: user.last_name,
      salutation: user.title,
      school: user.self_reported_school,
      email: email,
      source: source,
      subject: subject,
      newsletter: newsletter,           # we were asked to
      newsletter_opt_in: newsletter,    # set both of these
      phone: phone_number,
      website: url,
      adoption_status: using_openstax,
      num_students: num_students.to_i,
      os_accounts_id: user.id
    )

    lead.save

    if lead.errors.any?
      handle_errors(lead, user, role)
    else
      Rails.logger.info("PushSalesforceLead: pushed #{lead.id} for user #{user.id}")
    end

    # TODO write spec that SF User Missing makes BG job retry and sends email
  end

  def handle_errors(lead, user, role)
    message = "PushSalesforceLead error! #{lead.inspect}; User: #{user.id}; " \
              "Role: #{role}; Error: #{lead.errors.full_messages}"

    Rails.logger.warn(message)

    # TODO write the message as a DelayedNotification, sending to
    # Rails.application.secrets[:salesforce]['mail_recipients']

    fatal_error(code: :lead_error) # TODO write spec to show this fails background job
  end

end
