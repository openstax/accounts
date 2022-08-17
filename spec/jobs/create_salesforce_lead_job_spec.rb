require 'rails_helper'
include ActiveJob::TestHelper

RSpec.describe CreateSalesforceLeadJob, type: :job do

  let!(:school) { FactoryBot.create :school,
                                    salesforce_id: '0010B000021QuAyQAK',
                                    name:          'Test University'
  }

  let!(:instructor_user) { FactoryBot.create :user,
                                             role:           'instructor',
                                             faculty_status: 'confirmed_faculty',
                                             school:         school
  }

  describe "#perform_later" do
    it 'creates a lead for an instructor' do
      ActiveJob::Base.queue_adapter = :test

      CreateSalesforceLeadJob.perform_later(instructor_user.id)
      expect(CreateSalesforceLeadJob).to have_been_enqueued.with(instructor_user.id)
    end
  end
end
