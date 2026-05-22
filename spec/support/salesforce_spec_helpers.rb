module SalesforceSpecHelpers
  # Helper method to create a Salesforce contact mock
  def create_sf_contact(uuid:, faculty_verified:, contact_id: 'SF_CONTACT_001', school_id: 'SF_SCHOOL_001')
    contact = Salesforce::Records::Contact.new(
      id: contact_id,
      accounts_uuid: uuid,
      faculty_verified: faculty_verified,
      school_type: 'College/University (4)',
      adoption_status: 'Not Adopter',
      master_record_id: nil,
      is_deleted: false
    )

    # Mock the school association
    sf_school = Salesforce::Records::School.new(
      id: school_id,
      school_location: 'Domestic',
      is_kip: false,
      is_child_of_kip: false
    )
    allow(contact).to receive(:school).and_return(sf_school)
    allow(contact).to receive(:school_id).and_return(school_id)

    contact
  end

  # Helper method to stub the contact fetch in SyncContacts (used by
  # UpdateUserContactInfo, which is now a one-line shim).
  def stub_salesforce_contacts(contacts)
    allow_any_instance_of(Salesforce::SyncContacts).to receive(:fetch_contacts).and_return(contacts)
  end

  # Helper method to stub Sentry methods
  def stub_sentry
    allow(Sentry).to receive(:capture_check_in).and_return('check_in_id')
    allow(Sentry).to receive(:capture_message)
    allow(Sentry).to receive(:capture_exception)
  end

  # Replace ActiveForce's sfdc_client with an in-memory no-op so unit tests
  # never accidentally talk to the real Salesforce sandbox. Pair with
  # `restore_salesforce_records!` if your spec needs to revert.
  def stub_salesforce_records!
    test_client = Class.new do
      def query(*)      ; [] ; end
      def create(*)     ; nil; end
      def update(*)     ; nil; end
      def upsert(*)     ; nil; end
      def find(*)       ; nil; end
      def authenticate! ; true; end
    end.new
    ActiveForce.sfdc_client = test_client
  end

  def restore_salesforce_records!
    ActiveForce.clear_sfdc_client!
  end

  # Absorbed from the openstax_salesforce gem's SpecHelpers. Constrains an
  # ActiveForce query to records matching the given conditions (LIKE matches
  # for any string value containing '%'). Useful in sandbox-backed VCR specs
  # where you want to ignore unrelated rows.
  def limit_salesforce_queries(remote_class, **conditions)
    allow(remote_class).to receive(:query) do
      like_conditions = {}
      other_conditions = {}
      conditions.each_pair do |key, value|
        if value.is_a?(String) && value.include?('%')
          like_conditions[key] = value
        else
          other_conditions[key] = value
        end
      end
      remote_class.original_query.where(other_conditions)
    end
  end

  def limit_salesforce_queries_by_token(remote_class, token)
    case remote_class.new
    when Salesforce::Records::Contact, Salesforce::Records::Lead
      limit_salesforce_queries(remote_class, last_name: "%#{token}")
    else
      raise "Don't know how to apply to #{remote_class}"
    end
  end
end

RSpec.configure do |config|
  config.include SalesforceSpecHelpers
end
