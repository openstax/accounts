namespace :accounts do
  desc 'Update newly created field for adopter status from Salesforce'
  # rake accounts:update_adopter_status
  task update_adopter_status: [:environment] do
    loop do
      users = User.where(adopter_status: nil).where.not(salesforce_contact_id: nil).limit(250)

      contacts = OpenStax::Salesforce::Remote::Contact.select(
        :id,
        :adoption_status,
        :accounts_uuid
      )
      .where(id: users.map(&:salesforce_contact_id))
      .to_a
      .index_by(&:id)

      updated_users = users.map do |user|
        contact = contacts[user.salesforce_contact_id]
        user.adopter_status = contact.adoption_status
      end

      updated_users.transaction do
        updated_users.each(&:save!)
      end

      break if users.length < 250
    end
  end
end
