require 'rails_helper'

RSpec.describe UpdateSalesforceAssignableFields, type: :routine do
  let!(:non_assignable_student)    { FactoryBot.create :user }

  let!(:non_assignable_instructor) { FactoryBot.create :user, salesforce_contact_id: 'TESTCONTACT1' }

  let!(:assignable_student)        do
    FactoryBot.create(:user).tap do |user|
      FactoryBot.create :external_id, user: user
      FactoryBot.create :external_id, user: user
    end
  end

  let!(:assignable_instructor)     do
    FactoryBot.create(:user, salesforce_contact_id: 'TESTCONTACT2').tap do |user|
      FactoryBot.create :external_id, user: user
      FactoryBot.create :external_id, user: user
    end
  end

  context 'new School' do
    it "updates Salesforce Contact with Assignable user's info" do
      stub_contacts [ non_assignable_instructor, assignable_instructor ]

      expect_any_instance_of(OpenStax::Salesforce::Remote::Contact).to(
        receive(:assignable_interest=).with('Fully Integrated').and_call_original
      )
      expect_any_instance_of(OpenStax::Salesforce::Remote::Contact).to(
        receive(:assignable_adoption_date=).with(
          assignable_instructor.external_ids.map(&:created_at).min
        ).and_call_original
      )
      expect_any_instance_of(OpenStax::Salesforce::Remote::Contact).to receive(:save!)

      described_class.call
    end
  end

  def stub_contacts(users)
    sf_contacts = [users].flatten.map do |user|
      id = user.salesforce_contact_id
      [ id, OpenStax::Salesforce::Remote::Contact.new(id: id) ]
    end.to_h

    expect(OpenStax::Salesforce::Remote::Contact).to receive(:find) { |id| sf_contacts[id] }
  end
end
