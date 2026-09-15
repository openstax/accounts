module Newflow
  module EducatorSignup
    # Adds a school email as a new ContactInfo on an already-signed-in
    # educator's account, at the SheerID school-email gate (see
    # EducatorSignupController#educator_sheerid_form). Reuses the same
    # add-email machinery as the CS-form school_issued_email flow
    # (CreateEmailForUser) rather than inventing a new one.
    class AddSchoolEmail
      lev_handler

      uses_routine CreateEmailForUser, translations: {
        outputs: {
          map: { email: :school_email },
          scope: :school_email
        }
      }

      paramify :school_email do
        attribute :email, type: String
        validates :email, presence: true
      end

      protected #################

      attr_reader :user

      def setup
        @user = options[:user]
      end

      def authorized?
        @user && !@user.is_anonymous?
      end

      def handle
        email_param = school_email_params.email&.squish

        if invalid_email?(email_param)
          return fatal_error(
            code: :invalid_school_email,
            message: I18n.t(:"login_signup_form.school_email_invalid"),
            offending_inputs: :email
          )
        end

        run(CreateEmailForUser, email: email_param, user: user, is_school_issued: true)
        transfer_errors_from(user, { type: :verbatim }, :fail_if_errors)

        outputs.user = user
      end

      private #################

      # Same approach as EducatorSignup::CompleteProfile#invalid_email? for
      # the CS-form school_issued_email field: standard email format + MX
      # validation. Note this does NOT require the address to match the
      # .edu/.org heuristic - the gate is guidance, not a hard block, so any
      # valid, deliverable email is accepted here.
      def invalid_email?(email_value)
        email = EmailAddress.new(value: email_value)
        begin
          email.mx_domain_validation
          email.errors.any?
        rescue Mail::Field::IncompleteParseError
          true
        end
      end
    end
  end
end
