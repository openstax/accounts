module Newflow
  module EducatorSignup
    class CsVerificationRequest
      lev_handler
      uses_routine UpsertSalesforceLeadForCsVerification
      uses_routine CreateEmailForUser, translations: {
        outputs: {
          map: { email: :school_issued_email },
          scope: :school_issued_email
        }
      }

      OTHER = 'other'


      paramify :signup do
        attribute :school_name, type: String
        attribute :school_issued_email, type: String
        attribute :educator_specific_role, type: String
        attribute :other_role_name, type: String

        validates :school_name, presence: true
        validates :educator_specific_role, presence: true
        validates :other_role_name, presence: true
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

        unless user.contact_infos.where(value: email_address_value)
          run(CreateEmailForUser, email: email_address_value, user: outputs.user)
        end

        user.update(
          self_reported_school: signup_params.school_name,
          role: signup_params.educator_specific_role,
          other_role_name: other_role_name,
          is_profile_complete: true,
          is_educator_pending_cs_verification: true,
          faculty_status: User::PENDING_FACULTY,
        )
        transfer_errors_from(user, {type: :verbatim}, :fail_if_errors)

        outputs.user = user

        UpsertSalesforceLeadForCsVerification.perform_later(user: user)
      end

      private #################

      def other_role_name
        signup_params.educator_specific_role == OTHER ? signup_params.other_role_name.strip : nil
      end

      def check_params
        if signup_params.educator_specific_role.strip.downcase == OTHER &&
          signup_params.other_role_name.blank?

          param_error(:other_role_name, :other_must_be_entered)
        end

        if email_address_value.blank?
          param_error(:school_issued_email, :school_issued_email_must_be_entered)
        elsif email_address_value.present? && invalid_email?
          param_error(:school_issued_email, :school_issued_email_is_invalid)
        elsif email_address_value.present? && email_already_taken?
          param_error(:school_issued_email, :school_issued_email_is_taken)
        end
      end

      def invalid_email?
        e = EmailAddress.new(value: email_address_value)

        begin
          e.mx_domain_validation
          return e.errors.any?
        rescue Mail::Field::IncompleteParseError
          return true
        end
      end

      def email_already_taken?
        email = email_address_value
        user.contact_infos.where(value: email).none? && ContactInfo.verified.where(value: email).any?
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
