require 'rails_helper'

RSpec.describe AddAccountToSalesforceJob, type: :job do

  let!(:instructor_user) { FactoryBot.create :user,
                                             role: 'instructor',
                                             faculty_status: 'confirmed_faculty'
  }

  describe "#perform_later" do
    it 'creates an account record for an instructor' do
      ActiveJob::Base.queue_adapter = :test

      AddAccountToSalesforceJob.perform_later(instructor_user.id)
      expect(AddAccountToSalesforceJob).to have_been_enqueued.with(instructor_user.id)
    end
  end
end
