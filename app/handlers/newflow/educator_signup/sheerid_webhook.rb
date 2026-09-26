module Newflow
  module EducatorSignup
    class SheeridWebhook
      lev_handler

      protected ###############

      def authorized?
        true
      end

      def handle(verification_id=nil)
        verification_id ||= params.fetch('verificationId')

        details = fetch_details(verification_id)
        verification = record_verification(details, verification_id)
        user = resolve_user(verification_id, verification)

        if user.nil?
          report(verification, verification_id, user)
          return
        end

        # The user switched to a student account while this verification was in
        # flight. Applying it would re-attach the educator fields SwitchSignupRole
        # just cleared, and a 'success' step would strand them as confirmed_faculty
        # -- which SwitchSignupRole then refuses to undo. Record it and return 200
        # so SheerID doesn't retry.
        if user.student?
          SecurityLog.create!(
            event_type: :sheerid_webhook_ignored_after_role_switch,
            user: user,
            event_data: { verification_id: verification_id, current_step: verification.current_step }
          )
          return
        end

        user.with_lock do
          SecurityLog.create!(event_type: :sheerid_webhook_received, user: user)
          assign_verification_id(user, verification_id)
          apply_verification(user, verification, details, verification_id)
          SecurityLog.create!(user: user, event_type: :sheerid_webhook_processed)
        end

        report(verification, verification_id, user)

        CreateOrUpdateSalesforceLead.perform_later(user: user)

        OXPosthog.log(user, 'sheerid_verification_received', {
          result: verification.current_step,
          school_matched: user.school.present?,
          error_ids: verification.error_ids,
        })

        outputs.verification_id = verification_id
      end

      private #################

      def fetch_details(verification_id)
        details = SheeridAPI.get_verification_details(verification_id)
        return details if details.success?

        Sentry.capture_message(
          '[SheerID Webhook] fetching verification details FAILED',
          extra: { verification_id: verification_id, verification_details: details }
        )
        fatal_error(code: :sheerid_api_call_failed)
      end

      def record_verification(details, verification_id)
        SheeridVerification.record_webhook!(details, verification_id: verification_id)
      end

      def resolve_user(verification_id, verification)
        User.find_by(sheerid_verification_id: verification_id) ||
          EmailAddress.verified.find_by(value: verification.email)&.user
      end

      # Set the user's sheerid_verification_id only if they didn't already have
      # one -- we don't want to overwrite the approved one.
      def assign_verification_id(user, verification_id)
        if verification_id.present? && user.sheerid_verification_id.blank?
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
      end

      def apply_verification(user, verification, details, verification_id)
        if details.relevant?
          user.first_name = details.first_name
          user.last_name = details.last_name
          user.sheerid_reported_school = details.organization_name
          user.school = match_school(user.sheerid_reported_school)
        end

        user.sheer_id_webhook_received = true
        user.save!

        if details.relevant?
          SecurityLog.create!(
            event_type: :school_added_to_user_from_sheerid_webhook,
            user: user,
            event_data: { school: user.school }
          )
        end

        event_data = {
          verification_id: verification_id,
          current_step: verification.current_step,
          error_ids: verification.error_ids,
          rejection_reasons: verification.rejection_reasons,
        }

        user.advance_faculty_status!(verification.faculty_status_for_step, source: :accounts, event_data: event_data)

        SecurityLog.create!(event_type: outcome_event_type(verification), user: user, event_data: event_data)
      end

      def outcome_event_type(verification)
        case verification.current_step
        when SheeridVerification::VERIFIED then :fv_success_by_sheerid
        when SheeridVerification::REJECTED then :fv_reject_by_sheerid
        when SheeridVerification::ERROR
          verification.expired? ? :sheerid_webhook_expired : :sheerid_webhook_error
        else
          :sheerid_webhook_pending
        end
      end

      # Attempt to exactly match a school based on the sheerid_reported_school
      # field, then fall back to a fuzzy match on the name/city/state SheerID
      # embeds in a single string.
      def match_school(reported_school_name)
        school = School.find_by(sheerid_school_name: reported_school_name)
        return school if school

        match = SheeridAPI::SHEERID_REGEX.match(reported_school_name)
        name = match[1]
        city = match[2]
        state = match[3]

        # Sometimes the city and/or state are duplicated, so remove them
        name = name.chomp(" (#{city})") unless city.nil?
        name = name.chomp(" (#{state})") unless state.nil?
        name = name.chomp(" (#{city}, #{state})") unless city.nil? || state.nil?

        # For Homeschool, the city is "Any" and the state is missing
        city = nil if city == 'Any'

        School.fuzzy_search(name, city, state)
      end

      # expiredVerification is the ordinary end of a verification nobody
      # finished, not someone stuck -- SheerID ages the record out and calls the
      # webhook regardless of whether anyone ever reached step 4. Only report to
      # Sentry when there's a user attached: an anonymous expiry is unactionable
      # noise (h1, 9/25; ACCOUNTS-67Z), but a user who reached step 4 with this
      # outcome is worth seeing.
      def report(verification, verification_id, user)
        if user.nil?
          return if verification.error?

          Sentry.capture_message(
            "[SheerID Webhook] No user found with verification id (#{verification_id}) and email (#{verification.email})",
            extra: { verification_id: verification_id, verification: verification.attributes }
          )
        elsif verification.error?
          Sentry.capture_message(
            '[SheerID Webhook] error step received',
            level: :warning,
            extra: { user_id: user.id, verification_id: verification_id, error_ids: verification.error_ids }
          )
        end
      end
    end
  end
end
