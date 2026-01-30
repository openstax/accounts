module Newflow
  module EducatorSignup
    class SheeridWebhook
      lev_handler

      protected

      def authorized?
        true
      end

      def handle
        verification_id = params[:verification_id]
        return unless verification_id
        
        verification_details = fetch_verification_details(verification_id)
        return unless verification_details

        verification = find_or_initialize_verification(verification_id, verification_details)
        user = find_user_by_email(verification.email)
        return unless user

        log_webhook_received(user)
        
        # Check if this is a duplicate webhook for an already processed verification
        if duplicate_webhook?(user, verification_id, verification_details)
          log_duplicate_webhook(user, verification_id, verification_details)
          outputs.verification_id = verification_id
          return
        end

        # Return early if user is already confirmed faculty to avoid overwriting their status
        return if should_ignore_webhook_for_confirmed_user?(user, verification_id, verification_details)
        
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
            organization_name: details.organization_name,
            program_id: details.program_id,
            segment: details.segment,
            sub_segment: details.sub_segment,
            locale: details.locale,
            reward_code: details.reward_code,
            organization_id: details.organization_id,
            postal_code: details.postal_code,
            country: details.country,
            phone_number: details.phone_number,
            birth_date: details.birth_date,
            ip_address: details.ip_address,
            device_fingerprint_hash: details.device_fingerprint_hash,
            doc_upload_rejection_count: details.doc_upload_rejection_count,
            doc_upload_rejection_reasons: details.doc_upload_rejection_reasons,
            error_ids: details.error_ids,
            metadata: details.metadata
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

      def duplicate_webhook?(user, verification_id, details)
        # Check if this is a duplicate webhook for an already processed verification
        return false unless user.sheerid_verification_id == verification_id
        
        # If user is already confirmed faculty, don't touch it (support probably already confirmed them)
        return true if user.faculty_status == User::CONFIRMED_FACULTY
        
        # Check if we've already processed this verification step
        existing_verification = SheeridVerification.find_by(verification_id: verification_id)
        return false unless existing_verification
        
        # If the verification step hasn't changed, this might be a duplicate
        existing_verification.current_step == details.current_step
      end

      def log_duplicate_webhook(user, verification_id, details)
        SecurityLog.create!(
          event_type: :sheerid_webhook_duplicate_ignored, 
          user: user, 
          event_data: { 
            verification_id: verification_id, 
            current_step: details.current_step,
            faculty_status: user.faculty_status,
            reason: "Duplicate webhook for already processed verification"
          }
        )
      end

      def should_ignore_webhook_for_confirmed_user?(user, verification_id, details)
        return false unless user.faculty_status == User::CONFIRMED_FACULTY
        
        SecurityLog.create!(
          event_type: :sheerid_webhook_ignored, 
          user: user, 
          event_data: { 
            reason: "User already confirmed",
            verification_id: verification_id,
            current_step: details.current_step
          }
        )
        outputs.verification_id = verification_id
        true
      end

      def handle_user_verification(user, verification_id, details)
        if verification_id.present? && user.sheerid_verification_id.blank?
          user.update!(sheerid_verification_id: verification_id)
          SecurityLog.create!(event_type: :sheerid_verification_id_added_to_user_from_webhook, user: user, event_data: { verification_id: verification_id })
        elsif verification_id.present? && user.sheerid_verification_id != verification_id
          SecurityLog.create!(event_type: :sheerid_conflicting_verification_id, user: user, event_data: { 
            verification_id: verification_id, 
            existing_verification_id: user.sheerid_verification_id 
          })
        end
      end

      def update_user_with_verification_data(user, verification, details)
        return unless details.relevant?

        # Only update user data if it's more complete than what we already have
        # or if this is a successful verification
        should_update_user_data = should_update_user_data?(user, verification, details)

        if should_update_user_data
          user.update!(
            first_name: verification.first_name.presence || user.first_name,
            last_name: verification.last_name.presence || user.last_name,
            sheerid_reported_school: verification.organization_name,
            faculty_status: verification.current_step_to_faculty_status,
            sheer_id_webhook_received: true,
            school: find_or_fuzzy_match_school(verification.organization_name),
            sheerid_program_id: verification.program_id,
            sheerid_segment: verification.segment,
            sheerid_organization_id: verification.organization_id,
            sheerid_postal_code: verification.postal_code,
            sheerid_country: verification.country,
            sheerid_phone_number: verification.phone_number,
            sheerid_birth_date: verification.birth_date,
            sheerid_ip_address: verification.ip_address,
            sheerid_device_fingerprint_hash: verification.device_fingerprint_hash,
            sheerid_doc_upload_rejection_count: verification.doc_upload_rejection_count,
            sheerid_doc_upload_rejection_reasons: verification.doc_upload_rejection_reasons,
            sheerid_error_ids: verification.error_ids,
            sheerid_metadata: verification.metadata
          )

          SecurityLog.create!(event_type: :school_added_to_user_from_sheerid_webhook, user: user, event_data: { school: user.school })
        end
      end

      def should_update_user_data?(user, verification, details)
        # Always update for successful verifications
        return true if details.current_step == 'success'
        
        # Update if we don't have complete user data
        return true if user.first_name.blank? || user.last_name.blank?
        
        # Update if this verification has more complete data
        return true if verification.first_name.present? && verification.last_name.present? && 
                      verification.organization_name.present?
        
        false
      end

      def find_or_fuzzy_match_school(school_name)
        return nil unless school_name.present?
        
        School.find_by(sheerid_school_name: school_name) || fuzzy_match_school(school_name)
      end

      def fuzzy_match_school(school_name)
        match = SheeridAPI::SHEERID_REGEX.match(school_name)
        return nil unless match
        
        name, city, state = match[1], match[2], match[3]
        name = name.chomp(" (#{city})").chomp(" (#{state})").chomp(" (#{city}, #{state})")
        city = nil if city == 'Any'
        School.fuzzy_search(name, city, state)
      end

      def process_verification_step(user, verification_id, details)
        case details.current_step
        when 'rejected'
          update_user_status(user, User::REJECTED_BY_SHEERID, verification_id, :fv_reject_by_sheerid, details)
        when 'success'
          update_user_status(user, User::CONFIRMED_FACULTY, verification_id, :fv_success_by_sheerid, details)
        when 'collectTeacherPersonalInfo'
          update_user_status(user, User::PENDING_SHEERID, verification_id, :sheerid_webhook_request_more_info, details)
        when 'docUpload'
          update_user_status(user, User::PENDING_SHEERID, verification_id, :sheerid_webhook_doc_upload_required, details)
        when 'error'
          update_user_status(user, nil, verification_id, :sheerid_error, details)
        else
          update_user_status(user, nil, verification_id, :unknown_sheerid_response, details)
        end
      end

      def update_user_status(user, status, verification_id, event_type, details = nil)
        user.update!(faculty_status: status, sheerid_verification_id: verification_id) if status.present?
        
        event_data = { 
          verification_id: verification_id, 
          current_step: details&.current_step,
          faculty_status: user.faculty_status
        }
        
        # Add additional context for debugging
        if details
          event_data.merge!({
            program_id: details.program_id,
            segment: details.segment,
            organization_name: details.organization_name,
            error_ids: details.error_ids,
            doc_upload_rejection_count: details.doc_upload_rejection_count,
            doc_upload_rejection_reasons: details.doc_upload_rejection_reasons
          })
        end
        
        SecurityLog.create!(event_type: event_type, user: user, event_data: event_data)
      end

      def log_webhook_processed(user, verification_id, details)
        SecurityLog.create!(
          event_type: :sheerid_webhook_processed, 
          user: user, 
          event_data: { 
            verification_id: verification_id, 
            current_step: details.current_step,
            faculty_status: user.faculty_status,
            program_id: details.program_id,
            segment: details.segment,
            organization_name: details.organization_name
          }
        )
      end
    end
  end
end
