module Newflow
  module EducatorSignup
    class CompleteProfile
      OTHER = 'other'
      INSTRUCTOR = 'instructor'
      AS_PRIMARY = 'as_primary'
      AS_FUTURE = 'as_future'

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
      end

      protected ###############

      def authorized?
        !caller.is_anonymous?
      end

      def handle
        educator_params_check
        return if errors?

        caller.update(
          role: signup_params.educator_specific_role
        )
        transfer_errors_from(caller, {type: :verbatim}, :fail_if_errors)

        update_salesforce_lead
      end

      private #################

      def educator_params_check
        if signup_params.educator_specific_role.strip.downcase == OTHER &&
          signup_params.other_role_name.blank?

          param_error(:other_role_name, "other_must_be_entered")
        end

        if signup_params.educator_specific_role.strip.downcase  == INSTRUCTOR &&
          signup_params.using_openstax_how == AS_PRIMARY &&
          signup_params.books_used.blank?

          param_error(:books_used, "books_used_must_be_entered")
        end

        if signup_params.educator_specific_role.strip.downcase  == INSTRUCTOR &&
          signup_params.using_openstax_how == AS_FUTURE &&
          signup_params.subjects_of_interest.blank?

          param_error(:subjects_of_interest, "subjects_of_interest_must_be_entered")
        end

        if signup_params.educator_specific_role.strip.downcase  == INSTRUCTOR &&
          signup_params.num_students_per_semester_taught.blank?

          param_error(:num_students_per_semester_taught, "num_students_must_be_entered")
        end
      end

      def param_error(field, error_key)
        message = I18n.t(:"educator_profile_form.#{error_key}")
        nonfatal_error(
          code: field,
          message: message,
          offending_inputs: field
        )
      end

      def update_salesforce_lead
        # if Settings::Salesforce.push_leads_enabled
        #   UpdateSalesforceLead.perform_later(
        #     user: caller,
        #     num_students: signup_params.num_students_per_semester_taught,
        #     using_openstax: signup_params.using_openstax_how,
        #     subject: books_or_subjects,

        #     role: kind_of_educator,
        #     # school: signup_params.self_reported_school, # TODO

        #     # TODO: salesforce must be ready to accept these before we try to push them
        #     # more_specific_educator_role: signup_params.educator_specific_role || signup_params.other_role_name,
        #     # titles: signup_params.books_used.join(';'),
        #     # salesforce_lead_id: caller.salesforce_lead_id,
        #     # salesforce_contact_id: caller.salesforce_contact_id,

        #     # do not set source_application because this faculty access endpoint does
        #     # not have a strong indication of where the user is coming from
        #     source_application: nil
        #   )
        # end
      end

      def kind_of_educator
        signup_params.educator_specific_role == OTHER ? signup_params.other_role_name : signup_params.educator_specific_role
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
end
