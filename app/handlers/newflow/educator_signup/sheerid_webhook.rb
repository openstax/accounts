module Newflow
  module EducatorSignup
    class SheeridWebhook
      lev_handler

      protected

      def authorized?
        true
      end

      def handle(verification_id=nil)
        verification_id ||= params.fetch('verificationId')
        verification_details = fetch_verification_details(verification_id)
        return unless verification_details

        verification = find_or_initialize_verification(verification_id, verification_details)
        user = find_user_by_email(verification.email)
        return unless user

        log_webhook_received(user)
        handle_user_verification(user, verification_id, verification_details)
        update_user_with_verification_data(user, verification, verification_details)
        process_verification_step(user, verification_id, verification_details)

        CreateOrUpdateSalesforceLead.perform_later(user: user)
        log_webhook_processed(user, verification_id, verification_details)
        outputs.verification_id = verification_id
      end

      private

      def fetch_verification_details(verification_id)
        details = SheeridAPI.get_verification_details(verification_id)
        unless details.success?
          Sentry.capture_message("[SheerID Webhook] fetching verification details FAILED",
                                 extra: { verification_id: verification_id, verification_details: details })
          fatal_error(code: :sheerid_api_call_failed)
          return nil
        end
        details
      end

      def find_or_initialize_verification(verification_id, details)
        SheeridVerification.find_or_initialize_by(verification_id: verification_id).tap do |verification|
          verification.assign_attributes(
            email: details.email,
            current_step: details.current_step,
            first_name: details.first_name,
            last_name: details.last_name,
            organization_name: details.organization_name
          )
          verification.save
        end
      end

      def find_user_by_email(email)
        EmailAddress.find_by(value: email)&.user.tap do |user|
          unless user
            Sentry.capture_message("[SheerID Webhook] No user found with email (#{email})")
          end
        end
      end

      def log_webhook_received(user)
        SecurityLog.create!(event_type: :sheerid_webhook_received, user: user)
      end

      def handle_user_verification(user, verification_id, details)
        if user.faculty_status == User::CONFIRMED_FACULTY
          SecurityLog.create!(event_type: :sheerid_webhook_ignored, user: user, event_data: { reason: "User already confirmed" })
        elsif verification_id.present? && user.sheerid_verification_id.blank? && user.sheerid_verification_id != verification_id
          user.update!(sheerid_verification_id: verification_id)
          SecurityLog.create!(event_type: :sheerid_verification_id_added_to_user_from_webhook, user: user, event_data: { verification_id: verification_id })
        else
          SecurityLog.create!(event_type: :sheerid_conflicting_verification_id, user: user, event_data: { verification_id: verification_id })
        end
      end

      def update_user_with_verification_data(user, verification, details)
        return unless details.relevant?

        user.update!(
          first_name: verification.first_name,
          last_name: verification.last_name,
          sheerid_reported_school: verification.organization_name,
          faculty_status: verification.current_step_to_faculty_status,
          sheer_id_webhook_received: true,
          school: find_or_fuzzy_match_school(verification.organization_name)
        )
        SecurityLog.create!(event_type: :school_added_to_user_from_sheerid_webhook, user: user, event_data: { school: user.school })
      end

      def find_or_fuzzy_match_school(school_name)
        School.find_by(sheerid_school_name: school_name) || fuzzy_match_school(school_name)
      end

      def fuzzy_match_school(school_name)
        match = SheeridAPI::SHEERID_REGEX.match(school_name)
        name, city, state = match[1], match[2], match[3]
        name = name.chomp(" (#{city})").chomp(" (#{state})").chomp(" (#{city}, #{state})")
        city = nil if city == 'Any'
        School.fuzzy_search(name, city, state)
      end

      def process_verification_step(user, verification_id, details)
        case details.current_step
        when 'rejected'
          update_user_status(user, User::REJECTED_BY_SHEERID, verification_id, :fv_reject_by_sheerid)
        when 'success'
          update_user_status(user, User::CONFIRMED_FACULTY, verification_id, :fv_success_by_sheerid)
        when 'collectTeacherPersonalInfo'
          update_user_status(user, User::PENDING_SHEERID, verification_id, :sheerid_webhook_request_more_info, details.inspect)
        when 'error'
          update_user_status(user, nil, verification_id, :sheerid_error, details.inspect)
        else
          update_user_status(user, nil, verification_id, :unknown_sheerid_response, details.inspect)
        end
      end

      def update_user_status(user, status, verification_id, event_type, event_data = nil)
        user.update!(faculty_status: status, sheerid_verification_id: verification_id)
        SecurityLog.create!(event_type: event_type, user: user, event_data: { verification_id: verification_id, verification: event_data })
      end

      def log_webhook_processed(user, verification_id, details)
        SecurityLog.create!(event_type: :sheerid_webhook_processed, user: user, event_data: { verification_id: verification_id, verification_details: details.inspect, faculty_status: user.faculty_status })
      end
    end
  end
end
