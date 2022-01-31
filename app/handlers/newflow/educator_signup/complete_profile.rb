module Newflow
  module EducatorSignup
    class CompleteProfile

      OTHER = 'other'
      AS_PRIMARY = 'as_primary'
      INSTRUCTOR = 'instructor'
      AS_FUTURE = 'as_future'

      lev_handler

      uses_routine CreateEmailForUser, translations: {
        outputs: {
          map: { email: :school_issued_email },
          scope: :school_issued_email
        }
      }

      paramify :signup do
        attribute :school_name, type: String
        attribute :is_school_not_supported_by_sheerid, type: String
        attribute :is_country_not_supported_by_sheerid, type: String
        attribute :school_name, type: String
        attribute :school_issued_email, type: String
        attribute :educator_specific_role, type: String
        attribute :other_role_name, type: String
        attribute :who_chooses_books, type: String
        attribute :using_openstax_how, type: String
        attribute :num_students_per_semester_taught, type: Integer
        attribute :books_used, type: Object
        attribute :books_of_interest, type: Object
        attribute :is_cs_form, type: Object

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

        @did_use_sheerid = !((signup_params.is_school_not_supported_by_sheerid == 'true' ||
                            signup_params.is_school_not_supported_by_sheerid == '') ||
                           (signup_params.is_country_not_supported_by_sheerid == 'true' ||
                            signup_params.is_country_not_supported_by_sheerid == '') ||
                            user.is_sheerid_unviable? || signup_params.is_cs_form?)

        user.update!(
          role: signup_params.educator_specific_role,
          other_role_name: other_role_name,
          using_openstax_how: signup_params.using_openstax_how,
          who_chooses_books: signup_params.who_chooses_books,
          how_many_students: signup_params.num_students_per_semester_taught,
          which_books: which_books,
          self_reported_school: signup_params.school_name,
          is_profile_complete: true,
          is_educator_pending_cs_verification: !@did_use_sheerid
        )

        if !@did_use_sheerid && signup_params.is_cs_form?
          if !signup_params.school_issued_email.blank?
            # this user used the CS form and _should_ have provided us an email address - so let's add it, again, before output
            run(CreateEmailForUser, email: signup_params.school_issued_email, user: user, is_school_issued: true) # TODO: what is the point of just setting this to true? How is this used?
          end
        end

        transfer_errors_from(user, {type: :verbatim}, :fail_if_errors)

        # here's that output we've been waiting for...
        outputs.user = user

        if @did_use_sheerid
          # User used SheerID - we create their lead in ProcessSheeridWebhookRequest, not here.. and might not be instant
          return
        end

        # user needs CS review to become confirmed - set it as such in accounts
        user.update(
          requested_cs_verification_at: DateTime.now,
          faculty_status: User::PENDING_FACULTY
        )

        # Now we create the lead for the user... because we returned above is they did... again ProcessSheeridWebhookRequest
        create_salesforce_lead

      end

      private #################

      def create_salesforce_lead
        CreateSalesforceLead.perform_later(user: user)
      end

      def other_role_name
        signup_params.educator_specific_role == OTHER ? signup_params.other_role_name.strip : nil
      end

      def which_books
        if books_used.present?
          format_books_for_salesforce_string(signup_params.books_used)
        elsif books_of_interest.present?
          format_books_for_salesforce_string(signup_params.books_of_interest)
        end
      end

      def format_books_for_salesforce_string(books)
        books.reject(&:empty?)&.join(';')
      end

      def books_used
        signup_params.books_used.reject{ |b| b.blank? }
      end

      def books_of_interest
        signup_params.books_of_interest.reject{ |b| b.blank? }
      end

      def check_params
        role = signup_params.educator_specific_role.strip.downcase
        @did_use_sheerid = !signup_params.is_school_not_supported_by_sheerid == 'true' || !signup_params.is_country_not_supported_by_sheerid == 'true' || !user.is_sheerid_unviable?


        if (!@did_use_sheerid) &&
          signup_params.school_name.nil?
          param_error(:school_name, :school_name_must_be_entered)
        end

        if role == OTHER && signup_params.other_role_name.nil?
          param_error(:other_role_name, :other_must_be_entered)
        end

        if role  == INSTRUCTOR && signup_params.using_openstax_how == AS_PRIMARY && books_used.blank?
          param_error(:books_used, :books_used_must_be_entered)
        end

        if role  == INSTRUCTOR && signup_params.using_openstax_how != AS_PRIMARY && books_of_interest.blank?
          param_error(:books_of_interest, :books_of_interest_must_be_entered)
        end

        if role  == INSTRUCTOR && signup_params.num_students_per_semester_taught.blank?
          param_error(:num_students_per_semester_taught, :num_students_must_be_entered)
        end

        # if (!@did_use_sheerid || role != OTHER) && !signup_params.school_issued_email.blank?
        #   user_typed_email = signup_params.school_issued_email
        #   if user_typed_email.blank?
        #     param_error(:school_issued_email, :school_issued_email_must_be_entered)
        #   elsif user_typed_email.present? && invalid_email?
        #     param_error(:school_issued_email, :school_issued_email_is_invalid)
        #   elsif user_typed_email.present? && email_already_taken?
        #     param_error(:school_issued_email, :school_issued_email_is_taken)
        #   end
        # end
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
