class UpdateUserLeadInfo

  def self.call
    new.call
  end
  def call
    # TODO: we do want to limit this, but we need to update all the leads and schedule this first
    # we are only using this to check users created in the last month
    # start_date = Time.zone.now - 1.day
    # end_date = Time.zone.now - 30.day
    # for the query below when this is re-added
    # .where("created_at <= ? AND created_at >= ?", start_date, end_date)

    users = User.where(salesforce_contact_id: nil)
                .where.not(salesforce_lead_id: nil, role: :student, faculty_status: :rejected_faculty)

    leads = OpenStax::Salesforce::Remote::Lead.select(:id, :accounts_uuid, :verification_status)
                                              .where(accounts_uuid: users.map(&:uuid))
                                              .to_a
                                              .index_by(&:accounts_uuid)

    users.map do |user|
      lead = leads[user.uuid]

      unless lead.nil?
        previous_lead_id = user.salesforce_lead_id
        user.salesforce_lead_id = lead.id # it might change in SF lead merging

        if lead.id != previous_lead_id
          SecurityLog.create!(
            user:       user,
            event_type: :user_lead_id_updated_from_salesforce,
            event_data: { previous_lead_id: previous_lead_id, new_lead_id: lead.id }
          )
        end

        old_fv_status = user.faculty_status
        user.faculty_status = case lead.verification_status
                                when "confirmed_faculty"
                                  :confirmed_faculty
                                when "pending_faculty"
                                  :pending_faculty
                                when "rejected_faculty"
                                  :rejected_faculty
                                when "rejected_by_sheerid"
                                  :rejected_by_sheerid
                                when "incomplete_signup"
                                  :incomplete_signup
                                when "no_faculty_info"
                                  :no_faculty_info
                                when NilClass
                                  :no_faculty_info
                                else
                                  Sentry.capture_message("Unknown faculty_verified field: '#{
                                    lead.verification_status}'' on lead #{lead.id}")
                              end

        if user.faculty_status_changed?
          SecurityLog.create!(
            user: user,
            event_type: :salesforce_updated_faculty_status,
            event_data: {
              user_id: user.id,
              salesforce_lead_id: lead.id,
              old_status: old_fv_status,
              new_status: user.faculty_status
            }
          )
        end

        user.save if user.changed?
      end
    end
  end
end
