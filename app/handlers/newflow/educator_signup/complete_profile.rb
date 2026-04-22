module Newflow
  module EducatorSignup
    class CompleteProfile

      OTHER = 'other'
      AS_PRIMARY = 'as_primary'
      INSTRUCTOR = 'instructor'
      AS_FUTURE = 'as_future'
      AS_RECOMMENDING = 'as_recommending'

      EXPECTED_START_SEMESTERS = %w[
        this_semester next_semester next_academic_year just_exploring
      ].freeze

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
        attribute :books_used, type: Object
        attribute :books_used_details, type: Object
        attribute :books_of_interest, type: Object
        attribute :total_num_students, type: String
        attribute :is_cs_form, type: Object
        attribute :expected_start_semester, type: String

        validates(
          :educator_specific_role,
          inclusion: {
            in: %w(instructor researcher administrator other),
          }
        )
      end

      protected ###############

      attr_reader :user

      def setup
        @user = options[:user]
      end

      def authorized?
        @user && !@user.is_anonymous?
      end

      def handle
        # let the controller know this is the cs form, so we can redirect properly on error
        @is_on_cs_form = signup_params.is_cs_form?
        outputs.is_on_cs_form = @is_on_cs_form

        # validate the form
        check_params
        return if errors?

        # is this user coming from the sheerid flow? there are a few things we can check...
        @did_use_sheerid = !(signup_params.is_school_not_supported_by_sheerid == 'true' ||
                             signup_params.is_country_not_supported_by_sheerid == 'true' ||
                             user.is_sheerid_unviable? || @is_on_cs_form)

        total_students = calculate_total_students
        return if errors?

        @user.update!(
          role: signup_params.educator_specific_role,
          other_role_name: other_role_name,
          using_openstax_how: signup_params.using_openstax_how,
          who_chooses_books: signup_params.who_chooses_books,
          how_many_students: total_students,
          which_books: which_books,
          books_used_details: books_used_details,
          self_reported_school: signup_params.school_name,
          is_profile_complete: true,
          is_educator_pending_cs_verification: !@did_use_sheerid,
          expected_start_semester: expected_start_semester
        )
        # If anything happens during lead creation, it's helpful for us to have this on the log.
        SecurityLog.create!(user: user, event_type: :user_profile_complete, event_data: { books_used_details: books_used_details })

        if @is_on_cs_form
          SecurityLog.create!(
            user: user,
            event_type: :user_completed_cs_form
          )
          # user needs CS review to become confirmed - set it as such in accounts
          @user.update(
            requested_cs_verification_at: DateTime.now,
            faculty_status: User::PENDING_FACULTY
          )
          unless signup_params.school_issued_email.blank?
            # this user used the CS form and _should_ have provided us an email address -
            # so let's add it - validation happens before this in check_params
            run(CreateEmailForUser, email: signup_params.school_issued_email, user: @user, is_school_issued: true)
          end

          if user.school.nil? && !signup_params.school_name.blank?
            user.school = School.fuzzy_search signup_params.school_name
            user.save
          end
        end

        transfer_errors_from(@user, {type: :verbatim}, :fail_if_errors)

        CreateOrUpdateSalesforceLead.perform_later(user: @user)

        #output the user to the lev handler
        outputs.user = @user

      end

      protected

      def calculate_total_students
        if signup_params.using_openstax_how == AS_PRIMARY
          sum_book_student_counts
        elsif Settings::FeatureFlags.collect_student_count_all_paths
          validate_student_count!(
            signup_params.total_num_students,
            :total_num_students,
            'Total number of students must be a whole number greater than 0'
          )
        else
          sum_book_student_counts
        end
      end

      def sum_book_student_counts
        books_used_details.values.each_with_index.inject(0) do |total, (book, index)|
          count = validate_student_count!(
            book["num_students_using_book"],
            :"books_used_details_#{index}_num_students_using_book",
            'Number of students using each book must be a whole number greater than 0'
          )
          return nil if count.nil?

          total + count
        end
      end

      def validate_student_count!(value, field, message)
        if value.blank?
          errors.add(field, message)
          return nil
        end

        count = Integer(value, 10)
        if count <= 0
          errors.add(field, message)
          return nil
        end

        count
      rescue ArgumentError, TypeError
        errors.add(field, message)
        nil
      end

      private #################

      def expected_start_semester
        return nil if signup_params.expected_start_semester.blank?
        return nil unless EXPECTED_START_SEMESTERS.include?(signup_params.expected_start_semester)
        return nil unless [AS_PRIMARY, AS_RECOMMENDING].include?(signup_params.using_openstax_how)
        signup_params.expected_start_semester
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
        (signup_params.books_used || []).reject{ |b| b.blank? }
      end

      def books_used_details
        (signup_params.books_used_details || {}).reject do |k, v|
          k.blank? || v.dig('how_using_book').blank? || v.dig('num_students_using_book').blank?
        end
      end

      def books_of_interest
        (signup_params.books_of_interest || []).reject{ |b| b.blank? }
      end

      def check_params
        role = signup_params.educator_specific_role.strip.downcase

        if !@did_use_sheerid && signup_params.school_name.nil?
          param_error(:school_name, :school_name_must_be_entered)
        end

        if role == OTHER && signup_params.other_role_name.nil?
          param_error(:other_role_name, :other_must_be_entered)
        end

        if role == INSTRUCTOR && signup_params.using_openstax_how == AS_PRIMARY
          if books_used.blank?
            param_error(:books_used, :books_used_must_be_entered)
          end

          if books_used_details.blank?
            param_error(:books_used, :books_used_details_must_be_entered)
          end
        end

        if role == INSTRUCTOR && signup_params.using_openstax_how != AS_PRIMARY && books_of_interest.blank?
          param_error(:books_of_interest, :books_of_interest_must_be_entered)
        end

        if Settings::FeatureFlags.collect_student_count_all_paths &&
           signup_params.using_openstax_how != AS_PRIMARY &&
           signup_params.total_num_students.blank?
          param_error(:total_num_students, :fill_out)
        end

        if @is_on_cs_form
          # if they are on the CS form, we need school issued email address
          if signup_params.school_issued_email.blank?
            param_error(:school_issued_email, :school_issued_email_must_be_entered)
          end
        end
      end

      def invalid_email?
        email = EmailAddress.new(value: signup_params.school_issued_email)

        begin
          email.mx_domain_validation
          return email.errors.any?
        rescue Mail::Field::IncompleteParseError
          return true
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
