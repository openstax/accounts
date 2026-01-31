require 'rails_helper'

module Newflow
  describe CreateOrUpdateSalesforceLead, type: :routine do

    let(:user) do
      User.create do |u|
        u.first_name = "Max"
        u.last_name = "Liebermann"
        u.state = "activated"
        u.faculty_status = "pending_faculty"
        u.self_reported_school = "Test University"
        u.role = "instructor"
        u.school_type = "unknown_school_type"
        u.using_openstax = false
        u.receive_newsletter = false
        u.is_newflow = true
        u.phone_number = "+17133484799"
        u.school_location = "unknown_school_location"
        u.opt_out_of_cookies = false
        u.how_many_students = "35"
        u.which_books = "AP Macro Econ"
        u.who_chooses_books = "instructor"
        u.using_openstax_how = "as_primary"
        u.is_profile_complete = true
      end
    end

    before do
      # Mock the Salesforce School lookup for "Find Me A Home"
      mock_school = double('School', id: 'test_school_sf_id')
      allow(OpenStax::Salesforce::Remote::School).to receive(:find_by).with(name: 'Find Me A Home').and_return(mock_school)
      
      # Mock the Lead find_by and save operations
      mock_lead = double('Lead').as_null_object
      allow(mock_lead).to receive(:id).and_return('test_lead_id')
      allow(mock_lead).to receive(:email).and_return(user.best_email_address_for_salesforce)
      allow(mock_lead).to receive(:save).and_return(true)
      
      allow(OpenStax::Salesforce::Remote::Lead).to receive(:new).and_return(mock_lead)
      allow(OpenStax::Salesforce::Remote::Lead).to receive(:find_by).and_return(nil)
    end

    it 'works on the happy path' do
      expect(Rails.logger).not_to receive(:warn)

      lead = described_class[user: user]

      expect(user.salesforce_lead_id).not_to be_nil
    end
  end
end
