class SignupProfileInstructorFinal < SignupProfile

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

    paramify :complete_profile do
      attribute :first_name, type: String
      attribute :last_name, type: String
      attribute :email, type: String
      attribute :password, type: String
      attribute :is_title_1_school, type: boolean
      attribute :newsletter, type: boolean
      attribute :terms_accepted, type: boolean
      attribute :contract_1_id, type: Integer
      attribute :contract_2_id, type: Integer
      attribute :role, type: String
      attribute :phone_number, type: String
      attribute :country_code, type: String
    end
    def required_params
      @required_params ||= [:email, :first_name, :last_name, :password, :phone_number, :terms_accepted]
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
      @is_on_cs_form = complete_profile_params.is_cs_form?
      outputs.is_on_cs_form = @is_on_cs_form

      # validate the form
      validate_presence_of_required_params
      return if errors?

      # is this user coming from the sheerid flow? there are a few things we can check...
      @did_use_sheerid = !(complete_profile_params.is_school_not_supported_by_sheerid == 'true' ||
        complete_profile_params.is_country_not_supported_by_sheerid == 'true' ||
        user.is_sheerid_unviable? || @is_on_cs_form
      )

      @user.update!(
        role: complete_profile_params.educator_specific_role,
        other_role_name: other_role_name,
        using_openstax_how: complete_profile_params.using_openstax_how,
        who_chooses_books: complete_profile_params.who_chooses_books,
        how_many_students: complete_profile_params.num_students_per_semester_taught,
        which_books: which_books,
        self_reported_school: complete_profile_params.school_name,
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
          faculty_status: User::PENDING_FACULTY
        )
        unless complete_profile_params.school_issued_email.blank?
          # this user used the CS form and _should_ have provided us an email address -
          # so let's add it - validation happens before this in check_params
          run(CreateEmailForUser, email: complete_profile_params.school_issued_email, user: @user, is_school_issued: true)
        end
      end

      transfer_errors_from(@user, {type: :verbatim}, :fail_if_errors)

      #output the user to the lev handler
      outputs.user = @user

      if !user.is_educator_pending_cs_verification && !user.sheer_id_webhook_received
        # User used SheerID or needs CS verification - we create their lead in SheeridWebhook, not here.. and might not be instant
        SecurityLog.create!(
          user: user,
          event_type: :lead_creation_awaiting_sheerid_webhook,
        )
        return
      end
      # otherwise, we already heard from SheerID, so let's create the lead.
      # We check in SheeridWebhook to see if they completed their profile before creating lead

      # Now we create the lead for the user... because we returned above if they did... again SheeridWebhook
      CreateSalesforceLead.perform_later(user: @user)

    end

    private #################

    def other_role_name
      complete_profile_params.educator_specific_role == OTHER ? complete_profile_params.other_role_name.strip : nil
    end

    def which_books
      if books_used.present?
        format_books_for_salesforce_string(complete_profile_params.books_used)
      elsif books_of_interest.present?
        format_books_for_salesforce_string(complete_profile_params.books_of_interest)
      end
    end

    def format_books_for_salesforce_string(books)
      books.reject(&:empty?)&.join(';')
    end

    def books_used
      complete_profile_params.books_used.reject{ |b| b.blank? }
    end

    def books_of_interest
      complete_profile_params.books_of_interest.reject{ |b| b.blank? }
    end

    def validate_presence_of_required_params
      role = complete_profile_params.educator_specific_role.strip.downcase

      if !@did_use_sheerid && complete_profile_params.school_name.nil?
        param_error(:school_name, :school_name_must_be_entered)
      end

      if role == OTHER && complete_profile_params.other_role_name.nil?
        param_error(:other_role_name, :other_must_be_entered)
      end

      if role  == INSTRUCTOR && complete_profile_params.using_openstax_how == AS_PRIMARY && books_used.blank?
        param_error(:books_used, :books_used_must_be_entered)
      end

      if role  == INSTRUCTOR && complete_profile_params.using_openstax_how != AS_PRIMARY && books_of_interest.blank?
        param_error(:books_of_interest, :books_of_interest_must_be_entered)
      end

      if role  == INSTRUCTOR && complete_profile_params.num_students_per_semester_taught.blank?
        param_error(:num_students_per_semester_taught, :num_students_must_be_entered)
      end

      if @is_on_cs_form
        # if they are on the CS form, we need school issued email address
        if complete_profile_params.school_issued_email.blank?
          param_error(:school_issued_email, :school_issued_email_must_be_entered)
        end
      end
    end

    def invalid_email?
      email = EmailAddress.new(value: complete_profile_params.school_issued_email)

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

