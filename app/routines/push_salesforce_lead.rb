class PushSalesforceLead

  lev_routine express_output: :lead

  protected #################

  def exec(user:, email: nil, role:, phone_number:, school:, num_students:,
           using_openstax:, url:, newsletter:, subject:, source_application:)

    status.set_job_name(self.class.name)
    status.set_job_args(user: user.to_global_id.to_s)

    # If no email is given, pull from verified emails first, then unverified
    email ||= user.contact_infos.verified.first.try(:value) ||
              user.contact_infos.first.try(:value)

    fatal_error(code: :email_missing) if email.nil?

    if role.match(/student/i)
      source = "Student"
    else
      source = "OSC Faculty"
    end

    application_source = source_application.try(:lead_application_source)
    application_source = 'Accounts' if application_source.blank?

    salesforce_school_id = user.school&.salesforce_id
    lead = OpenStax::Salesforce::Remote::Lead.new(
      salesforce_contact_id: user.salesforce_contact_id,
      first_name: user.first_name,
      last_name: user.last_name,
      salutation: user.title,
      school: school || user.self_reported_school,
      email: email,
      source: source,
      subject: subject,
      phone: phone_number,
      website: url,
      adoption_status: using_openstax,
      num_students: num_students.to_i,
      os_accounts_id: user.id,
      application_source: application_source,
      role: role,

      # Salesforce needs both of these for the newsletter
      newsletter: newsletter,
      newsletter_opt_in: newsletter,

      # Both of these hold the school ID, they are just used in different places within Salesforce
      account_id: salesforce_school_id,
      school_id: salesforce_school_id
    )

    lead.save

    if lead.errors.any?
      handle_errors(lead, user, role)
    else
      log_success(lead, user)
      user.salesforce_lead_id = lead.id
      user.faculty_status = :pending_faculty if !user.student? && !user.confirmed_faculty?
      user.save if user.changed?
      transfer_errors_from(user, {type: :verbatim}, true)
    end

    outputs[:lead] = lead

    # TODO write spec that SF User Missing makes BG job retry and sends email
  end

  private ###################

  def log_success(lead, user)
    Rails.logger.info("PushSalesforceLead: pushed #{lead.id} for user #{user.id}")
  end

  def handle_errors(lead, user, role)
    message = '[PushSalesforceLead] ERROR'
    full_error_message = lead&.errors&.full_messages
    error_code = :lead_error

    Rails.logger.warn(message + "#{lead&.inspect}; User: #{user.id}; Role: #{role}; Error: #{full_error_message}")
    Raven.capture_message(
      message,
      extra: {
        user_id: user.id,
        lead: lead&.inspect,
        lead_errors: full_error_message,
        error_code: error_code
      },
      user: { id: user.id, lead: lead&.id }
    )

    fatal_error(code: error_code)
  end

end
