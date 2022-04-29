module EducatorSignup
  class CompleteProfile

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
      attribute :num_students_per_semester_taught, type: Object
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
      @user && !@user.is_anonymous?
    end

    def handle # rubocop:disable Metrics/MethodLength
      # let the controller know this is the cs form, so we can redirect properly on error
      @is_on_cs_form = signup_params.is_cs_form?
      outputs.is_on_cs_form = @is_on_cs_form

      # is this user coming from the sheerid flow? there are a few things we can check...
      @did_use_sheerid = !(signup_params.is_school_not_supported_by_sheerid&.empty? ||
        signup_params.is_country_not_supported_by_sheerid&.empty? ||
        !user.is_sheerid_unviable? || !@is_on_cs_form)

      # validate the form
      check_params
      return if errors?

      @user.update!(
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

      if @is_on_cs_form
        SecurityLog.create!(
          user: user,
          event_type: :user_completed_cs_form
        )
        # user needs CS review to become confirmed - set it as such in accounts
        @user.update(
          requested_cs_verification_at: DateTime.now,
          faculty_status: :pending_faculty
        )
        if signup_params.school_issued_email.present?
          # this user used the CS form and _should_ have provided us an email address -
          # so let's add it - validation happens before this in check_params
          run(CreateEmailForUser, email: signup_params.school_issued_email, user: @user,
is_school_issued: true)
        end
      else
        # If user did not need CS verification but still needs to be pending, set
        # them to pending state
        # This is everyone, unless SheerID sets it to something else in
        # sheerid_webhook when we hear back from their webhook
        # Otherwise, we can see who didn't fill out their profile with a faculty
        # status of :incomplete_signup
        if @user.faculty_status == :incomplete_signup && !@did_use_sheerid
          @user.faculty_status = :pending_faculty
          SecurityLog.create!(
            user:       user,
            event_type: :faculty_status_updated,
            event_data: { old_status: "incomplete", new_status: "pending" }
          )
        end
      end

      transfer_errors_from(@user, {type: :verbatim}, :fail_if_errors)

      #output the user to the lev handler
      outputs.user = @user

      if @did_use_sheerid
        # User used SheerID or needs CS verification - we create their lead in
        # SheeridWebhook, not here.. and might not be instant
        SecurityLog.create!(
          user: user,
          event_type: :lead_creation_awaiting_sheerid_webhook,
        )
        return
      end

      # Now we create the lead for the user... because we returned above
      # if they did... again SheeridWebhook
      CreateSalesforceLeadJob.perform_later(@user.id)


    end

    private #################

    def other_role_name
      signup_params.educator_specific_role == 'other' ? signup_params.other_role_name.strip : nil
    end

    def which_books
      if signup_params.books_used != nil
        format_books_for_salesforce_string(signup_params.books_used)
      elsif signup_params.books_of_interest != nil
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

      if signup_params.school_name&.nil?
        param_error(:school_name, :school_name_must_be_entered)
      end

      if role == 'other' && signup_params.other_role_name.nil?
        param_error(:other_role_name, :other_must_be_entered)
      end

      if role  == :instructor &&
         signup_params.using_openstax_how == :as_primary &&
         books_used.blank?
        param_error(:books_used, :books_used_must_be_entered)
      end

      if role  == :instructor && signup_params.using_openstax_how != :as_primary &&
         books_of_interest.blank?
        param_error(:books_of_interest, :books_of_interest_must_be_entered)
      end

      if role  == :instructor && signup_params.num_students_per_semester_taught.blank?
        param_error(:num_students_per_semester_taught, :num_students_must_be_entered)
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
