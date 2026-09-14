require 'rails_helper'

RSpec.describe Salesforce::Records::Contact do
  it 'maps to the Contact SObject' do
    expect(described_class.table_name).to eq('Contact')
  end

  %i[
    id name first_name last_name email faculty_verified last_modified_at
    school_id school_type all_emails adoption_status accounts_uuid lead_source
    signup_date assignable_interest assignable_adoption_date
    master_record_id is_deleted
  ].each do |attr|
    it "responds to ##{attr}" do
      expect(described_class.new).to respond_to(attr)
    end
  end
end
