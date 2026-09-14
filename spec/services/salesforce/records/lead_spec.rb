require 'rails_helper'

RSpec.describe Salesforce::Records::Lead do
  it 'maps to the Lead SObject' do
    expect(described_class.table_name).to eq('Lead')
  end

  %i[
    id name first_name last_name email phone source application_source
    role position title subject_interest school city state state_code country
    accounts_uuid os_accounts_id verification_status adoption_status adoption_json
    num_students who_chooses_books b_r_i_marketing title_1_school newsletter
    newsletter_opt_in self_reported_school sheerid_school_name account_id school_id
    signup_date tracking_parameters expected_start_semester
    is_converted converted_contact_id
  ].each do |attr|
    it "responds to ##{attr}" do
      expect(described_class.new).to respond_to(attr)
    end
  end
end
