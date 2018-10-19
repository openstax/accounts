class FacultyAccessApply

  lev_handler

  uses_routine SendContactInfoConfirmation

  def self.include_common_params_in(paramifier)
    paramifier.instance_exec(&(proc {
      # All children of this handler should know about all of
      # these fields (because all may be used in this parent
      # handler), but only some should always be required;
      # some children will require specific ones in addition

      attribute :role, type: String
      attribute :first_name, type: String
      attribute :last_name, type: String
      attribute :suffix, type: String
      attribute :email, type: String
      attribute :school, type: String
      attribute :phone_number, type: String
      attribute :subjects, type: Object
      attribute :url, type: String
      attribute :num_students, type: Integer
      attribute :num_students_book, type: Object
      attribute :using_openstax, type: String
      attribute :newsletter, type: boolean

      # All children must require these fields:

      validates :first_name, presence: true
      validates :last_name, presence: true
      validates :email, presence: true
      validates :school, presence: true
      validates :phone_number, presence: true
      validates :url, presence: true
    }))
  end

  def authorized?
    caller.is_activated?
  end

  def handle
    # Save and start confirmation process if the email is new

    if caller.contact_infos.where(value: email).none?
      # If email in use, it'd be too late to tell them when they confirm it
      fatal_error(code: :email_in_use, offending_inputs: [:apply, :email]) if email_in_use?

      new_email = EmailAddress.new(value: email)
      new_email.user = caller
      new_email.save

      transfer_errors_from(new_email, {scope: :apply}, true)

      run(SendContactInfoConfirmation, contact_info: new_email)
      outputs[:new_email] = new_email
    end

    # Update user information

    fatal_error(code: :invalid_role) if !User.non_student_known_roles.include?(apply_params.role)

    caller.role                 = apply_params.role
    caller.first_name           = apply_params.first_name
    caller.last_name            = apply_params.last_name
    caller.suffix               = apply_params.suffix      if !apply_params.suffix.blank?
    caller.self_reported_school = apply_params.school

    caller.save

    transfer_errors_from(caller, {type: :verbatim}, true)

    # Send the lead off

    if Settings::Salesforce.push_leads_enabled
      PushSalesforceLead.perform_later(
        user: caller,
        email: email,
        role: caller.role,
        phone_number: apply_params.phone_number,
        school: caller.self_reported_school,
        num_students: apply_params.num_students,
        using_openstax: apply_params.using_openstax,
        subject: SubjectsUtils.form_choices_to_salesforce_string(apply_params.subjects),
        url: apply_params.url,
        newsletter: apply_params.newsletter,
        # do not set source_application because this faculty access endpoint does
        # not have a strong indication of where the user is coming from
        source_application: nil
      )
    end

  end

  def email
    apply_params.email.strip
  end

  def email_in_use?
    ContactInfo.verified.where(value: email).any?
  end

end
