require 'rails_helper'

module Newflow
  describe CreateOrUpdateSalesforceLead, type: :routine do

    before do
      stub_salesforce_lead
      stub_salesforce_school
    end

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

    it 'works on the happy path' do
      expect(Rails.logger).not_to receive(:warn)

      lead = described_class[user: user]

      expect(user.salesforce_lead_id).not_to be_nil
    end
  end
end
