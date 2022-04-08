class AddNewAccountToSalesforceJob < ApplicationJob
  queue_as :salesforce_accounts_sync

  def perform(user_id)
    user = User.find(user_id)
    sf_ox_account = OpenStax::Salesforce::Remote::OpenStaxAccount.new(
      account_id:            user.id,
      account_uuid:          user.uuid.to_s,
      account_role:          user.role.titleize,
      faculty_status:        user.faculty_status,
      salesforce_contact_id: user&.salesforce_contact_id,
      salesforce_lead_id:    user&.salesforce_lead_id,
      signup_date:           user.created_at.strftime("%Y-%m-%dT%H:%M:%S%z"),
      account_environment:   Rails.application.secrets.environment_name
    )

    begin
      sf_ox_account.save!
      user.salesforce_ox_account_id = sf_ox_account.id
      # This means the lead was converted or deleted.. or is otherwise not available anymore
    rescue Restforce::ErrorCode::InsufficientAccessOnCrossReferenceEntity
      user.salesforce_ox_account_id = nil
    rescue Restforce::ErrorCode::DuplicateValue
      user.salesforce_ox_account_id = sf_ox_account.id
      Sentry.capture_message("Duplicate UUIDs detected. Hopefully this is a test environment! Updating to new ox_account_id (#{sf_ox_account.id})User uuid: #{user.uuid}")
    rescue StandardError => se
      Sentry.capture_exception se
    end

    begin
      if user.save!
        SecurityLog.create!(
          user:       user,
          event_type: :account_created_or_synced_with_salesforce,
          event_data: { sf_ox_account_id: sf_ox_account.id }
        )
      end
    rescue ActiveRecord::RecordInvalid => se
      SecurityLog.create!(
        user:       user,
        event_type: :salesforce_error,
        event_data: { sf_ox_account_id: sf_ox_account.id }
      )
      Sentry.capture_exception se
    end
  end
end
