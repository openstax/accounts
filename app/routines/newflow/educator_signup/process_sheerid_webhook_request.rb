module Newflow
  module EducatorSignup
    # When a POST request comes in from SheerID, we:
    # save the verification id  and
    class ProcessSheeridWebhookRequest

      lev_routine active_job_enqueue_options: { queue: :educator_signup_queue }

      protected ###############

      def exec(verification_id:)
        status.set_job_name(self.class.name)
        status.set_job_args(verification_id: verification_id)

        verification_details_from_sheerid = SheeridAPI.get_verification_details(verification_id)
        if !verification_details_from_sheerid.success?
          Sentry.capture_message("[ProcessSheeridWebhookRequest] fetching verification details FAILED",
            extra: { verification_id: verification_id, verification_details: verification_details_from_sheerid },
            user: { verification_id: verification_id }
          )
          fatal_error(code: :sheerid_api_call_failed)
        end

        # grab the details from what SheerID sends back and add them to the verification object
        verification = SheeridVerification.find_or_initialize_by(verification_id: verification_id)
        verification.email = verification_details_from_sheerid.email
        verification.current_step = verification_details_from_sheerid.current_step
        verification.first_name = verification_details_from_sheerid.first_name
        verification.last_name = verification_details_from_sheerid.last_name
        verification.organization_name = verification_details_from_sheerid.organization_name
        verification.save

        existing_user = EmailAddress.verified.find_by(value: verification.email)&.user

        if !existing_user.present?
          Sentry.capture_message("[ProcessSheeridWebhookRequest] No user found with verification id (#{verification_id}) "\
            "and email (#{verification.email})",
           extra: { verification_id: verification_id, verification_details_from_sheer_id: verification_details_from_sheerid },
           user: { verification_id: verification_id }
          )
          return
        end

        # Set the user's sheerid_verification_id only if they didn't already have one  we don't want to overwrite the approved one
        if verification_id.present? && existing_user.sheerid_verification_id.blank?
          existing_user.update!(sheerid_verification_id: verification_id)

          SecurityLog.create!(
            event_type: :user_updated_using_sheerid_data,
            user: existing_user,
            event_data: { verification: verification.inspect }
          )
        else
          SecurityLog.create!(
            event_type: :sheerid_conflicting_verification_id,
            user: existing_user,
            event_data: { verification: verification.inspect }
          )
        end


        # Update the user account with the data returned from SheerID
        if verification_details_from_sheerid.relevant?
          existing_user.first_name = verification.first_name
          existing_user.last_name = verification.last_name
          existing_user.sheerid_reported_school = verification.organization_name
          existing_user.faculty_status = verification.current_step_to_faculty_status

          # Attempt to exactly match a school based on the sheerid_reported_school field
          school = School.find_by sheerid_school_name: existing_user.sheerid_reported_school

          if school.nil?
            # No exact match found, so attempt to fuzzy match the school name
            match = SheeridAPI::SHEERID_REGEX.match existing_user.sheerid_reported_school
            name = match[1]
            city = match[2]
            state = match[3]

            # Sometimes the city and/or state are duplicated, so remove them
            name = name.chomp(" (#{city})") unless city.nil?
            name = name.chomp(" (#{state})") unless state.nil?
            name = name.chomp(" (#{city}, #{state})") unless city.nil? || state.nil?

            # For Homeschool, the city is "Any" and the state is missing
            city = nil if city == 'Any'

            school = School.fuzzy_search name, city, state
          end

          existing_user.school = school
        end

        user_changed = existing_user.changed?
        if user_changed
          existing_user.save
          transfer_errors_from(existing_user, {type: :verbatim}, :fail_if_errors)
        end

        if verification.current_step == 'rejected'
          if !user.rejected_faculty?
            user.faculty_status = User::REJECTED_FACULTY
            user.sheerid_verification_id = verification_id
            user.save
          end
        elsif verification.present?
          SecurityLog.create!(
            event_type: :user_updated_using_sheerid_data,
            user: existing_user,
            event_data: { verification: verification.inspect }
          ) if user_changed
        end

        # if we got the webhook back after the user submitted the profile, they didn't get a lead built yet
        # We just make sure they don't have a lead or contact id yet
        if existing_user.salesforce_lead_id.blank? && existing_user.salesforce_contact_id.blank?
          CreateSalesforceLead.perform_later(user: existing_user)
        end

        outputs.verification = verification
      end
    end
  end
end
