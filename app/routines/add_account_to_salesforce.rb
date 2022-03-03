class AddAccountToSalesforce

  lev_routine active_job_enqueue_options: { queue: :salesforce }

  def exec(user:)
      sf_ox_account = OpenStax::Salesforce::Remote::OpenStaxAccount.find_or_initialize_by(
        account_uuid: user.uuid,
      )

      sf_ox_account.account_id = user.id
      sf_ox_account.account_role = user.role.capitalize,
      sf_ox_account.salesforce_contact_id = user&.salesforce_contact_id,
      sf_ox_account.salesforce_lead_id = user&.salesforce_lead_id,
      sf_ox_account.signup_date = user.created_at.strftime("%Y-%m-%dT%H:%M:%S%z")
      sf_ox_account.account_environment = Rails.application.secrets.environment_name

      Sentry.capture_message(sf_ox_account.errors) unless sf_ox_account.save!
  end

  def log(message, level = :info)
    Rails.logger.tagged(self.class.name) { Rails.logger.public_send level, message }
  end
end
