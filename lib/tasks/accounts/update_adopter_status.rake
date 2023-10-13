namespace :accounts do
  desc 'Update newly created field for adopter status from Salesforce'
  # rake accounts:update_adopter_status
  task update_adopter_status: [:environment] do
    contacts ||= OpenStax::Salesforce::Remote::Contact.select(
      :id,
      :adoption_status,
      :accounts_uuid
    )
    .where("Accounts_UUID__c != null")
    .to_a

    contacts.each { | contact |
      u = User.where(salesforce_contact_id: contact.id)
      u.adopter_status = contact.adoption_status
      u.save!
    }
  end
end
