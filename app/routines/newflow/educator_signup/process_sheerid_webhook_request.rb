module Newflow
  module EducatorSignup
    # When a POST request comes in from SheerID, we:
    # save the verification id  and
    class ProcessSheeridWebhookRequest

      # Extract name, city and state from SheerID response when possible
      # 1. \A       - Beginning of string
      # 2. (.*?)    - Capturing group for name can lazy match anything
      # 3. (?: \(   - Optional non-capturing group for city and state with open parenthesis
      # 4. ([^,)]+) - Capturing group for city can match anything without comma or close parenthesis
      # 5. (?:,     - Optional non-capturing group for state with a comma and whitespace
      # 6. ([^)]+)  - Capturing group for state can match anything without close parenthesis
      # 7. )?       - Close optional non-capturing group for state
      # 8. \))?     - Close optional non-capturing group for city and state
      # 9. \z       - End of string
      SHEERID_REGEX = /\A(.*?)(?: \(([^,)]+)(?:, ([^)]+))?\))?\z/

      lev_routine active_job_enqueue_options: { queue: :educator_signup_queue }
      uses_routine UpsertSheeridVerification
      uses_routine SheeridRejectedEducator

      protected ###############

      def exec(verification_id:)
        status.set_job_name(self.class.name)
        status.set_job_args(verification_id: verification_id)

        verification_details = SheeridAPI.get_verification_details(verification_id)
        if !verification_details.success?
          Raven.capture_message("[ProcessSheeridWebhookRequest] fetching verification details FAILED",
            extra: { verification_id: verification_id, verification_details: verification_details },
            user: { verification_id: verification_id }
          )
          fatal_error(code: :sheerid_api_call_failed)
        end

        verification = upsert_verification(verification_id, verification_details)
        existing_user = EmailAddress.verified.find_by(value: verification.email)&.user

        if !existing_user.present?
          Rails.logger.warn(
            "[ProcessSheeridWebhookRequest] No user found with verification id (#{verification_id}) "\
            "and email (#{verification.email})"
          )
          return
        end

        if verification.errors.none? && verification.verified?
          VerifyEducator.perform_later(verification_id: verification_id, user: existing_user)
        elsif verification.rejected?
          run(SheeridRejectedEducator, user: existing_user, verification_id: verification_id)
        elsif verification.present?
          existing_user.sheerid_verification_id = verification_id \
            if existing_user.sheerid_verification_id.blank?

          if verification_details.relevant?
            existing_user.first_name = verification.first_name
            existing_user.last_name = verification.last_name
            existing_user.sheerid_reported_school = verification.organization_name
            existing_user.faculty_status = verification.current_step_to_faculty_status

            # Attempt to exactly match a school based on the sheerid_reported_school field
            school = School.find_by sheerid_reported_school: existing_user.sheerid_reported_school

            if school.nil?
              # No exact match found, so attempt to fuzzy match the school name
              match = SHEERID_REGEX.match existing_user.sheerid_reported_school
              name = match[1]
              city = match[2]
              state = match[3]

              # Sometimes the city and/or state are duplicated, so remove them
              name = name.chomp(" (#{city})") unless city.nil?
              name = name.chomp(" (#{state})") unless state.nil?
              name = name.chomp(" (#{city}, #{state})") unless city.nil? || state.nil?

              # For Homeschool, the city is "Any" and the state is missing
              city = nil if city == 'Any'

              school = School.fuzzy_match name, city, state
            end

            existing_user.school = school
          end

          if existing_user.changed?
            existing_user.save
            transfer_errors_from(existing_user, {type: :verbatim}, :fail_if_errors)
            SecurityLog.create!(
              event_type: :user_updated_using_sheerid_data,
              user: existing_user,
              event_data: { verification: verification.inspect }
            )
          end
        end

        outputs.verification = verification
      end

      private #################

      def upsert_verification(verification_id, details)
        @verification ||= run(UpsertSheeridVerification,
          verification_id: verification_id,
          details: details
        ).outputs.verification
      end

    end
  end
end
