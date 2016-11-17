class PushSalesforceLead

  lev_routine

  protected

  def exec(user:, role:, phone_number:, school:, num_students:, using_openstax:, url:, newsletter:)

    status.set_job_name(self.class.name)
    status.set_job_args(user: user.to_global_id.to_s)

    # Get email with try -- should be there, but who knows
    email = user.contact_infos.verified.first.try(:value)

    adoption_status =
    case using_openstax
    when /something/
      "Confirmed Adoption Won"
    when /something/
      "Piloting book this semester"
    when /something/
      "Confirmed Will Recommend"
    when /something/
      "High Interest in Adopting"
    when /something/
      "Not using"
    else
      nil
    end

    source = "Instructor" == role ? "OSC Faculty" : "OSC User"

    lead = Salesforce::Lead.new(
      first_name: user.first_name,
      last_name: user.last_name,
      salutation: user.title,
      school: user.self_reported_school,
      email: email,
      source: source,
      newsletter: newsletter,           # we were asked to
      newsletter_opt_in: newsletter,    # set both of these
      phone: phone_number,
      website: url,
      adoption_status: adoption_status,
      num_students: num_students
    )

    lead.save

    handle_errors(lead, user, role)

    # TODO write spec that SF User Missing makes BG job retry and sends email
  end

  def handle_errors(lead, user, role)
    return if lead.errors.none?

    message = "PushSalesforceLead error! #{lead.inspect}; User: #{user.id}; " \
              "Role: #{role}; Error: #{lead.errors.full_messages}"

    Rails.logger.warn(message)

    # TODO write the message as a DelayedNotification, sending to
    # Rails.application.secrets[:salesforce]['mail_recipients']

    fatal_error(code: :lead_error) # TODO write spec to show this fails background job
  end

end
