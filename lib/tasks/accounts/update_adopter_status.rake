namespace :accounts do
  desc 'Update newly created field for adopter status from Salesforce'
  # rake accounts:update_adopter_status
  task update_adopter_status: [:environment] do
    last_id = nil
    loop do
      users = User.where(adopter_status: nil).order(:id).limit(250)
      users = users.where("id > #{last_id}") unless last_id.nil?
      last_id = users.last&.id

      begin
        contacts = OpenStax::Salesforce::Remote::Contact.select(
          :id,
          :adoption_status,
          :accounts_uuid
        )
        .where(id: users.map(&:salesforce_contact_id))
        .index_by(&:id)
        .to_a

        updated_users = users.map do |user|
          contact = contacts[user.salesforce_contact_id]
          user.adopter_status = contact.adoption_status
        end
        
        updated_users.transaction do
          updated_users.save!
        end
      rescue StandardError => se
        Sentry.capture_exception se
      end

      break if users.length < 250
    end
  end
end
