module EducatorSignup
  class SheeridWebhook
    lev_handler

    protected ###############

    def authorized?
      true
    end

    def handle(verification_id=nil) # rubocop:disable Metrics/MethodLength
      unless verification_id
        verification_id = params.fetch('verificationId')
      end
      verification_details_from_sheerid = SheeridAPI.get_verification_details(verification_id)

      if !verification_details_from_sheerid.success?
        Sentry.capture_message(
          "[SheerID Webhook] fetching verification details FAILED",
          extra: {
            verification_id: verification_id,
            verification_details: verification_details_from_sheerid
          }
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

      user = EmailAddress.verified.find_by(value: verification.email)&.user

      if user.blank?
        Sentry.capture_message(
          "[SheerID Webhook] No user found with verification id (#{verification_id}) "\
          "and email (#{verification.email})",
          extra: {
            verification_id: verification_id,
            verification_details_from_sheer_id: verification_details_from_sheerid
          }
        )
        return
      end

      # update the security log and the user to say we got the webhook - we use
      # this in lead processing
      SecurityLog.create!(event_type: :sheerid_webhook_received, user: user)

      # Set the user's sheerid_verification_id only if they didn't already have
      # one  we don't want to overwrite the approved one
      if verification_id.present? && user.sheerid_verification_id.blank? &&
         user.sheerid_verification_id != verification_id
        user.update!(sheerid_verification_id: verification_id)

        SecurityLog.create!(
          event_type: :sheerid_verification_id_added_to_user_from_webhook,
          user: user,
          event_data: { verification_id: verification_id }
        )
      else
        SecurityLog.create!(
          event_type: :sheerid_conflicting_verification_id,
          user: user,
          event_data: { verification_id: verification_id }
        )
      end


      # Update the user account with the data returned from SheerID
      if verification_details_from_sheerid.relevant?
        user.first_name = verification.first_name
        user.last_name = verification.last_name
        user.sheerid_reported_school = verification.organization_name
        user.faculty_status = verification.current_step_to_faculty_status
        user.sheer_id_webhook_received = true

        # Attempt to exactly match a school based on the sheerid_reported_school field
        school = School.find_by sheerid_school_name: user.sheerid_reported_school

        if school.nil?
          # No exact match found, so attempt to fuzzy match the school name
          match = SheeridAPI::SHEERID_REGEX.match user.sheerid_reported_school
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

        user.school = school

        SecurityLog.create!(
          event_type: :school_added_to_user_from_sheerid_webhook,
          user: user,
          event_data: { school_name: school.name, school_salesforce_id: school.salesforce_id }
        )
      end

      if verification.current_step == 'rejected'
        user.update!(faculty_status: User::REJECTED_BY_SHEERID,
sheerid_verification_id: verification_id)
        SecurityLog.create!(
          event_type: :fv_reject_by_sheerid,
          user: user,
          event_data: { status: "User Rejected By SheerID", verification_id: verification_id })
      elsif verification.current_step == 'success'
        user.update!(faculty_status: User::CONFIRMED_FACULTY,
sheerid_verification_id: verification_id)
        SecurityLog.create!(
          event_type: :fv_success_by_sheerid,
          user: user,
          event_data: { status: "User Faculty Verified by SheerID",
verification_id: verification_id })
      elsif verification.current_step == 'collectTeacherPersonalInfo'
        user.update!(faculty_status: User::PENDING_SHEERID,
sheerid_verification_id: verification_id)
        SecurityLog.create!(
          event_type: :sheerid_webhook_request_more_info,
          user: user,
          event_data: { status: "SheerID Requested More Information",
verification: verification_details_from_sheerid.inspect })
      elsif verification.current_step == 'error'
        user.update!(faculty_status: User::REJECTED_BY_SHEERID,
sheerid_verification_id: verification_id)
        user.update!(sheerid_verification_id: verification_id)
        SecurityLog.create!(
          event_type: :sheerid_error,
          user: user,
          event_data: { status: "Error from SheerID",
verification: verification_details_from_sheerid.inspect })
      else
        user.update!(faculty_status: User::REJECTED_BY_SHEERID,
sheerid_verification_id: verification_id)
        SecurityLog.create!(
          event_type: :unknown_sheerid_response,
          user: user,
          event_data: { status: "Unexpected Response from SheerID",
verification: verification_details_from_sheerid.inspect })
      end

      # if we got the webhook back after the user submitted the profile, they
      # didn't get a lead built yet
      # We just make sure they don't have a lead or contact id yet
      if user.salesforce_lead_id.blank? && user.salesforce_contact_id.blank? &&
         user.is_profile_complete
        CreateSalesforceLeadJob.perform_later(user_id: user.id)
      end

      SecurityLog.create!(user: user, event_type: :sheerid_webhook_processed)
      outputs.verification_id = verification_id
    end
  end
end
