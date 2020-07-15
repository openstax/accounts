module Newflow
  module EducatorSignup
    class CompleteProfile

      OTHER = 'other'
      INSTRUCTOR = 'instructor'
      AS_PRIMARY = 'as_primary'
      AS_FUTURE = 'as_future'

      lev_handler

      paramify :signup do
        attribute :is_school_not_supported_by_sheerid, type: String
        attribute :is_country_not_supported_by_sheerid, type: String
        attribute :school_name, type: String
        attribute :educator_specific_role, type: String
        attribute :other_role_name, type: String
        attribute :who_chooses_books, type: String
        attribute :using_openstax_how, type: String
        attribute :num_students_per_semester_taught, type: Integer
        attribute :books_used, type: Object

        validates(
          :educator_specific_role,
          inclusion: {
            in: %w(instructor administrator other),
          }
        )
      end

      protected ###############

      attr_reader :user

      def setup
        @user = options[:user]
      end

      def authorized?
        user && !user.is_anonymous?
      end

      def handle
        check_params
        return if errors?

        user.update(
          role: signup_params.educator_specific_role,
          other_role_name: other_role_name,
          using_openstax_how: signup_params.using_openstax_how,
          who_chooses_books: signup_params.who_chooses_books,
          how_many_students: signup_params.num_students_per_semester_taught,
          which_books: signup_params.books_used&.reject(&:empty?)&.join(';'),
          self_reported_school: signup_params.school_name,
          is_profile_complete: true
        )
        transfer_errors_from(user, {type: :verbatim}, :fail_if_errors)

        outputs.is_educator_pending_cs_verification = user.rejected_faculty?
        outputs.user = user

        update_salesforce_lead
      end

      private #################

      def update_salesforce_lead
        UpdateSalesforceLead.perform_later(user: user)
      end

      def other_role_name
        signup_params.educator_specific_role == OTHER ? signup_params.other_role_name.strip : nil
      end

      def check_params
        if (signup_params.is_school_not_supported_by_sheerid == 'true' ||
          signup_params.is_country_not_supported_by_sheerid == 'true') &&
          signup_params.school_name.blank?

          param_error(:school_name, :school_name_must_be_entered)
        end

        if signup_params.educator_specific_role.strip.downcase == OTHER &&
          signup_params.other_role_name.blank?

          param_error(:other_role_name, :other_must_be_entered)
        end

        if signup_params.educator_specific_role.strip.downcase  == INSTRUCTOR &&
          signup_params.using_openstax_how == AS_PRIMARY &&
          signup_params.books_used.blank?

          param_error(:books_used, :books_used_must_be_entered)
        end

        if signup_params.educator_specific_role.strip.downcase  == INSTRUCTOR &&
          signup_params.num_students_per_semester_taught.blank?

          param_error(:num_students_per_semester_taught, :num_students_must_be_entered)
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

    end
  end
end
