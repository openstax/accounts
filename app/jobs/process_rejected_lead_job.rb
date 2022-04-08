class ProcessRejectedLeadJob < ApplicationJob
  queue_as :salesforce_lead_sync

  def perform(lead_id, accounts_uuid)
    return unless (rejected_user = User.find_by!(uuid: accounts_uuid))

    if rejected_user.salesforce_lead_id.blank? || rejected_user.salesforce_lead_id != lead_id
      rejected_user.salesforce_lead_id = lead_id
      SecurityLog.create!(
        user:       rejected_user,
        event_type: :user_lead_id_updated_from_salesforce,
        event_data: { lead_id: lead_id }
      )
    end

    old_fv_status = rejected_user.faculty_status
    rejected_user.faculty_status = :rejected_faculty

    SecurityLog.create!(
      user:       rejected_user,
      event_type: :salesforce_updated_faculty_status,
      event_data: { user_id: rejected_user.id, salesforce_contact_id: lead_id, old_status: old_fv_status, new_status: rejected_user.faculty_status }
    )

    if rejected_user.changed?
      rejected_user.save!
    end
  end
end
