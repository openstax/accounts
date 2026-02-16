module SalesforceSpecHelpers
  # Helper method to create a Salesforce contact mock
  def create_sf_contact(uuid:, faculty_verified:, contact_id: 'SF_CONTACT_001', school_id: 'SF_SCHOOL_001')
    contact = OpenStax::Salesforce::Remote::Contact.new(
      id: contact_id,
      accounts_uuid: uuid,
      faculty_verified: faculty_verified,
      school_type: 'College/University (4)',
      adoption_status: 'Not Adopter',
      grant_tutor_access: false
    )

    # Mock the school association
    sf_school = OpenStax::Salesforce::Remote::School.new(
      id: school_id,
      school_location: 'Domestic',
      is_kip: false,
      is_child_of_kip: false
    )
    allow(contact).to receive(:school).and_return(sf_school)
    allow(contact).to receive(:school_id).and_return(school_id)

    contact
  end

  # Helper method to stub the salesforce_contacts method
  def stub_salesforce_contacts(contacts)
    allow_any_instance_of(UpdateUserContactInfo).to receive(:salesforce_contacts).and_return(contacts)
  end

  # Helper method to stub Sentry methods
  def stub_sentry
    allow(Sentry).to receive(:capture_check_in).and_return('check_in_id')
    allow(Sentry).to receive(:capture_message)
  end
end

RSpec.configure do |config|
  config.include SalesforceSpecHelpers
end
