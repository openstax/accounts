namespace :accounts do
  desc 'Create leads for faculty verified by SheerID and never sent to Salesforce'
  # rake accounts:create_leads_for_instructors_not_sent_to_sf
  # To be run to fix users that were not sent to SF during bug from 26Jan22
  #  to xxFeb22 (hotfix release date)
  task :create_leads_for_instructors_not_sent_to_sf, [:day] => [:environment] do |t, args|
    # get all the instructors that don't have lead or contact ids
    users = User
            .where(
              salesforce_contact_id: nil, salesforce_lead_id: nil, role: :instructor,
              state: :activated, faculty_status: :confirmed_faculty
            )
            .or(User.where.not(sheerid_verification_id: nil))
    users.each { |user|
      CreateSalesforceLeadJob.perform_later(user_id: user.id)
    }
  end
end
