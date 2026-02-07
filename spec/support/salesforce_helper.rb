module SalesforceTestHelper
  # Replaces disable_sfdc_client - stubs ActiveForce so no real SF calls happen
  def disable_sfdc_client
    allow(ActiveForce)
      .to receive(:sfdc_client)
      .and_return(double('null object').as_null_object)
  end

  # Stubs SF Lead creation/lookup to return a mock lead
  def stub_salesforce_lead(id: 'MOCK_LEAD_ID')
    lead = double('Lead', id: id, errors: double(messages: {}))
    allow(lead).to receive(:[]=)
    allow(lead).to receive(:save).and_return(true)
    # Accept any attribute writer calls (e.g. lead.first_name = ...)
    allow(lead).to receive(:method_missing).and_return(nil)
    allow(lead).to receive(:respond_to_missing?).and_return(true)
    allow(OpenStax::Salesforce::Remote::Lead).to receive(:new).and_return(lead)
    allow(OpenStax::Salesforce::Remote::Lead).to receive(:find_by).and_return(lead)
    lead
  end

  # Stubs SF School lookup
  def stub_salesforce_school(id: 'MOCK_SCHOOL_ID', name: 'Find Me A Home')
    school = double('SFSchool', id: id, name: name)
    allow(OpenStax::Salesforce::Remote::School).to receive(:find_by).and_return(school)
    school
  end

  # Stubs SF Contact lookup
  def stub_salesforce_contact(id: 'MOCK_CONTACT_ID')
    contact = double('SFContact', id: id)
    allow(OpenStax::Salesforce::Remote::Contact).to receive(:find).and_return(contact)
    contact
  end
end

RSpec.configure do |config|
  config.include SalesforceTestHelper
end
