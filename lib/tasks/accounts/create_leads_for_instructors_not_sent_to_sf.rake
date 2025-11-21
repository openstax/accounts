namespace :accounts do
  desc 'Create contacts for faculty verified by SheerID and never sent to Salesforce'
  # rake accounts:create_leads_for_instructors_not_sent_to_sf
  task :create_leads_for_instructors_not_sent_to_sf, [:day] => [:environment] do |t, args|
    # get all the instructors that don't have contact ids and have a complete profile
    users = User.where(salesforce_contact_id: nil, role: :instructor, is_profile_complete: true)
    STDOUT.puts "This will process #{users.count} users. Do you want to continue? (y/n)"

    begin
      input = STDIN.gets.strip.downcase
    end until %w(y n).include?(input)

    if input !='y'
      STDOUT.puts "Cancelling contact creation for abandoned users."
      return
    end

    users.each do |user|
      contact = OpenStax::Salesforce::Remote::Contact.select(:id, :faculty_verified).find_by(accounts_uuid: user.uuid)

      if contact.nil?
        Newflow::CreateOrUpdateSalesforceContact.call(user: user)
      else
        # set the contact id, this will update their status in UpdateUserContactInfo
        user.salesforce_contact_id = contact.id
        user.save
      end
    end
  end
end
