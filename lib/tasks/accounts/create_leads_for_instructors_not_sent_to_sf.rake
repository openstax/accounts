namespace :accounts do
  desc 'Create leads for faculty verified by SheerID and never sent to Salesforce'
  # rake accounts:create_leads_for_instructors_not_sent_to_sf
  task :create_leads_for_instructors_not_sent_to_sf, [:day] => [:environment] do |t, args|
    # get all the instructors that don't have lead or contact ids and have a complete profile
    users = User.where(salesforce_contact_id: nil, salesforce_lead_id: nil, role: :instructor, is_profile_complete: true)

    users.each do |user|
      lead = OpenStax::Salesforce::Remote::Lead.select(:id, :verification_status).find_by(accounts_uuid: user.uuid)

      if lead.nil?
        Newflow::CreateOrUpdateSalesforceLead.call(user: user)
      else
        # set the lead id, this will update their status in UpdateUserLeadInfo
        user.salesforce_lead_id = lead.id
        user.save
      end
    end
  end
end
