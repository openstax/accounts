namespace :accounts do
  desc 'Update newly created field for adopter status from Salesforce'
  # rake accounts:update_adopter_status
  task update_adopter_status: [:environment] do
    last_id = nil
    loop do
      contacts = OpenStax::Salesforce::Remote::Contact.select(
        :id,
        :adoption_status,
        :accounts_uuid
      )
      .where("Accounts_UUID__c != null")
      .order(:Id)
      .limit(250)
      contacts = contacts.where("Id > '#{last_id}'") unless last_id.nil?
      contacts = contacts.to_a
      last_id = contacts.last&.id

      begin
        user_by_salesforce_id = User.where(
          salesforce_contact_id: contacts.map(&:id)
        ).index_by(&:salesforce_contact_id)

        updated_contacts = contacts.map do |contact|
          user = user_by_salesforce_id[contact.id]
          user.adopter_status = contact.adoption_status
          user.save!
        end
      rescue StandardError => se
        Sentry.capture_exception se
      end

      break if contacts.length < 250
    end
  end
end
