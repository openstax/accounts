class UpdateUserLeadInfo
  BATCH_SIZE = 250

  def self.call
    new.call
  end

  def call
    loop do
      users = User.where(salesforce_contact_id: nil).where.not(salesforce_lead_id: nil, role: :student, faculty_status: :rejected_faculty).limit(BATCH_SIZE)

      leads = OpenStax::Salesforce::Remote::Lead.select(:id, :accounts_uuid, :verification_status).where(accounts_uuid: users.map(&:uuid)).to_a.index_by(&:accounts_uuid)

      updated_users = users.map do |user|
        lead = leads[user.uuid]

        begin
          user.salesforce_lead_id = lead.id # it might change in SF lead merging

          old_fv_status = user.faculty_status
          user.faculty_status = case lead.faculty_verified
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
                                      lead.faculty_verified}'' on lead #{lead.id}")
                                end

          if user.faculty_status_changed?
            SecurityLog.create!(
              user:       user,
              event_type: :salesforce_updated_faculty_status,
              event_data: {
                user_id: user.id,
                salesforce_lead_id: lead.id,
                old_status: old_fv_status,
                new_status: user.faculty_status
              }
            )
          end
        rescue NoMethodError
          Sentry.capture_message("User #{user.id} unable to be synced with lead #{lead.id}")
        end
      end

      updated_users.transaction do
        updated_users.each(&:save!)
      end

      break if users.length < BATCH_SIZE
    end
  end
end
