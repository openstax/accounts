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
          salesforce_contact_id: caller.salesforce_contact_id,
          num_students: signup_params.num_students_per_semester_taught,
          using_openstax: signup_params.using_openstax_how,
          subject: books_or_subjects,
          # do not set source_application because this faculty access endpoint does
          # not have a strong indication of where the user is coming from
          source_application: nil
        )
      end
    end

    def books_or_subjects
      subjects = signup_params.subjects_of_interest.reject{ |s| s == '' }
      titles = signup_params.books_used.reject{ |b| b == '' }

      if subjects.size >  0
        return subjects.join(';')
      elsif titles.size > 0
        return titles.join(';')
      end
    end
  end
end
