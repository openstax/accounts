module Newflow
  module EducatorSignup
    class CsVerificationRequest
      lev_handler
      uses_routine UpsertSalesforceInfoForCsVerification
      uses_routine CreateEmailForUser, translations: {
        outputs: {
          map: { email: :school_issued_email },
          scope: :school_issued_email
        }
      }

      OTHER = 'other'
      AS_PRIMARY = 'as_primary'
      INSTRUCTOR = 'instructor'
      AS_FUTURE = 'as_future'

      paramify :signup do
        attribute :school_name, type: String
        attribute :school_issued_email, type: String
        attribute :educator_specific_role, type: String
        attribute :other_role_name, type: String
        attribute :who_chooses_books, type: String
        attribute :using_openstax_how, type: String
        attribute :num_students_per_semester_taught, type: String
        attribute :books_used, type: Object
        attribute :books_of_interest, type: Object

        validates(
          :educator_specific_role,
          inclusion: {
            in: %w(instructor administrator other),
          }
        )
      end

      protected ###############

      attr_reader :user, :email_address_value

      def setup
        @user = options[:user]
        @email_address_value = signup_params.school_issued_email
      end

      def authorized?
        user && !user.is_anonymous?
      end

      def handle
        check_params
        return if errors?

        user.update(
          self_reported_school: signup_params.school_name,
          role: signup_params.educator_specific_role,
          other_role_name: other_role_name,
          who_chooses_books: signup_params.who_chooses_books,
          using_openstax_how: signup_params.using_openstax_how,
          how_many_students: signup_params.num_students_per_semester_taught,
          which_books: which_books,
          is_profile_complete: true,
          is_educator_pending_cs_verification: true,
          requested_cs_verification_at: DateTime.now,
          faculty_status: User::PENDING_FACULTY
        )
        transfer_errors_from(user, {type: :verbatim}, :fail_if_errors)
        SecurityLog.create!(event_type: :user_updated, user: user)

        outputs.user = user

        if !users_existing_email.present?
          run(CreateEmailForUser, email: email_address_value, user: user, is_school_issued: true)
        end

        UpsertSalesforceInfoForCsVerification.perform_later(user: user)
      end

      private #################

      def which_books
        if books_used.present?
          format_books_for_salesforce_string(signup_params.books_used)
        elsif books_of_interest.present?
          format_books_for_salesforce_string(signup_params.books_of_interest)
        end
      end

      def other_role_name
        signup_params.educator_specific_role == OTHER ? signup_params.other_role_name.strip : nil
      end

      def check_params
        if signup_params.school_name.blank?
          param_error(:school_name, :school_name_must_be_entered)
        end

        if signup_params.educator_specific_role.strip.downcase == OTHER &&
          signup_params.other_role_name.blank?

          param_error(:other_role_name, :other_must_be_entered)
        end

        if signup_params.educator_specific_role.strip.downcase  == INSTRUCTOR &&
          signup_params.using_openstax_how == AS_PRIMARY && books_used.blank?

          param_error(:books_used, :books_used_must_be_entered)
        end

        if signup_params.educator_specific_role.strip.downcase  == INSTRUCTOR &&
          signup_params.using_openstax_how != AS_PRIMARY && books_of_interest.blank?

          param_error(:books_of_interest, :books_of_interest_must_be_entered)
        end

        if email_address_value.blank?
          param_error(:school_issued_email, :school_issued_email_must_be_entered)
        elsif email_address_value.present? && invalid_email?
          param_error(:school_issued_email, :school_issued_email_is_invalid)
        elsif email_address_value.present? && email_already_taken?
          param_error(:school_issued_email, :school_issued_email_is_taken)
        end
      end

      def books_used
        signup_params.books_used.reject{ |b| b.blank? }
      end

      def books_of_interest
        signup_params.books_of_interest.reject{ |b| b.blank? }
      end

      def format_books_for_salesforce_string(books)
        books.reject(&:empty?)&.join(';')
      end

      def invalid_email?
        email = EmailAddress.new(value: email_address_value)

        begin
          email.mx_domain_validation
          return email.errors.any?
        rescue Mail::Field::IncompleteParseError
          return true
        end
      end

      def email_already_taken?
        email = email_address_value
        users_existing_email.none? && ContactInfo.verified.where(value: email).any?
      end

      def users_existing_email
        @users_existing_email ||= user.contact_infos.where(value: email_address_value)
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
