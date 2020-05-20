module Newflow
  class EducatorCompleteProfile
    lev_handler

    paramify :signup do
      attribute :educator_specific_role, type: String
      attribute :other_role_name, type: String
      attribute :how_are_books_chosen, type: String
      attribute :using_openstax_how, type: String
      attribute :num_students_per_semester_taught, type: Integer
      attribute :subjects_of_interest, type: Object
      attribute :books_used, type: Object

      validates(
        :educator_specific_role,
        inclusion: {
          in: %w(instructor administrator other),
        }
      )

      validates(
        :num_students_per_semester_taught,
        numericality: {
          only_integer: true,
        }
      )
    end

    protected ###############

    def authorized?
      !caller.is_anonymous?
    end

    def handle
      caller.update(state: User::EDUCATOR_COMPLETE_PROFILE)
      transfer_errors_from(caller, {type: :verbatim}, true)

      push_lead_to_salesforce
    end

    private #################

    def push_lead_to_salesforce
      if Settings::Salesforce.push_leads_enabled
        PushSalesforceLead.perform_later(
          user: caller,
          num_students: signup_params.num_students_per_semester_taught,
          using_openstax: signup_params.using_openstax_how,
          subject: books_or_subjects,

          role: caller.role,
          phone_number: caller.phone_number,
          school: caller.self_reported_school,
          url: '',
          newsletter: caller.receive_newsletter?,

          # TODO: salesforce must be ready to accept these before we try to push them
          # more_specific_educator_role: signup_params.educator_specific_role || signup_params.other_role_name,
          # titles: signup_params.books_used.join(';'),
          # salesforce_contact_id: caller.salesforce_contact_id,

          # do not set source_application because this faculty access endpoint does
          # not have a strong indication of where the user is coming from
          source_application: nil
        )
      end
    end

    def books_or_subjects
      subjects = signup_params.subjects_of_interest&.reject(&:empty?)
      titles = signup_params.books_used&.reject(&:empty?)

      if subjects&.any?
        return subjects.join(';')
      elsif titles&.any?
        return titles.join(';')
      end
    end
  end
end
