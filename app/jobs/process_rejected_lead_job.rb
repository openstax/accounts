class ProcessRejectedLeadJob < ApplicationJob
  queue_as :salesforce_rejected_leads

  def perform(accounts_uuid)
    return unless (rejected_user = User.find_by!(uuid: accounts_uuid))

    if rejected_user.salesforce_lead_id.blank?
      rejected_user.salesforce_lead_id = reject_lead.id
      SecurityLog.create!(
        user:       rejected_user,
        event_type: :user_lead_id_updated_from_salesforce,
        event_data: { lead_id: reject_lead.id }
      )
    elsif rejected_user.salesforce_lead_id != sf_lead.id
      rejected_user.salesforce_lead_id = reject_lead.id
      SecurityLog.create!(
        user:       rejected_user,
        event_type: :user_lead_id_updated_from_salesforce,
        event_data: { lead_id: reject_lead.id }
      )
    end

    old_fv_status                = rejected_user.faculty_status
    rejected_user.faculty_status = case reject_lead.faculty_verified
                                     when "rejected_faculty"
                                       :rejected_faculty
                                     else
                                       Sentry.capture_message("Attempting to reject a lead that shouldn't be: '#{
                                         reject_lead.faculty_verified}'' on lead #{reject_lead.id}")
                                   end
    if rejected_user.faculty_status_changed?
      SecurityLog.create!(
        user:       rejected_user,
        event_type: :salesforce_updated_faculty_status,
        event_data: { user_id: rejected_user.id, salesforce_contact_id: reject_lead.id, old_status: old_fv_status, new_status: rejected_user.faculty_status }
      )
    end

    if rejected_user.changed?
      rejected_user.save!
    end
  end
end
