module Account
  # Creates an unverified InstructorConnection claim from the student account
  # page's "Who teaches your class?" card — either by picking a verified
  # instructor from the autocomplete (instructor_id present) or via the
  # "my instructor isn't listed" fallback form (free-text fields present).
  #
  # Always creates an *unverified* claim: no Salesforce push, no impact
  # counting. See InstructorConnection for why.
  class CreateInstructorConnection
    lev_handler

    paramify :instructor_connection_form do
      attribute :instructor_id
      attribute :instructor_name, type: String
      attribute :school_name, type: String
      attribute :course, type: String
      attribute :term, type: String
      attribute :instructor_email, type: String
    end

    protected #################

    def authorized?
      caller.present? && !caller.is_anonymous? && caller.student?
    end

    def handle
      instructor = matched_instructor

      if instructor_connection_form_params.instructor_id.present? && instructor.nil?
        fatal_error(code: :instructor_not_found, message: 'That instructor could not be found.')
        return
      end

      connection = InstructorConnection.new(
        student: caller,
        instructor: instructor,
        instructor_name: instructor&.name.presence || instructor_connection_form_params.instructor_name.to_s.strip,
        school: instructor&.school,
        school_name: instructor&.school&.name.presence || instructor_connection_form_params.school_name.to_s.strip,
        course: instructor_connection_form_params.course.presence,
        term: instructor_connection_form_params.term.presence,
        instructor_email: instructor.present? ? nil : instructor_connection_form_params.instructor_email.presence,
        status: 'unverified'
      )

      if connection.save
        outputs.instructor_connection = connection
      else
        transfer_errors_from(connection, { type: :verbatim }, true)
      end
    end

    private

    def matched_instructor
      id = instructor_connection_form_params.instructor_id
      return nil if id.blank?

      User.instructor.confirmed_faculty.find_by(id: id)
    end
  end
end
