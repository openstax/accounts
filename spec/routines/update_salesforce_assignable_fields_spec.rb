require 'rails_helper'

describe UpdateSalesforceAssignableFields, type: :routine do
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
          assignable_instructor.external_ids.map(&:created_at).min.strftime('%Y-%m-%d')
        ).and_call_original
      )
      expect_any_instance_of(OpenStax::Salesforce::Remote::Contact).to receive(:save!)

      described_class.call
    end
  end

  context 'Contact already Fully Integrated' do
    it 'does not call save! when the adoption date already matches' do
      adoption_date = assignable_instructor.external_ids.map(&:created_at).min.to_date
      contact = build_contact(
        id: 'TESTCONTACT2', assignable_interest: 'Fully Integrated',
        assignable_adoption_date: adoption_date
      )
      stub_found_contacts('TESTCONTACT2' => contact)

      expect(contact).not_to receive(:assignable_interest=)
      expect(contact).not_to receive(:assignable_adoption_date=)
      expect(contact).not_to receive(:save!)

      described_class.call
    end

    it 'saves without reassigning assignable_interest when the adoption date differs' do
      contact = build_contact(
        id: 'TESTCONTACT2', assignable_interest: 'Fully Integrated', assignable_adoption_date: nil
      )
      stub_found_contacts('TESTCONTACT2' => contact)

      expect(contact).not_to receive(:assignable_interest=)
      expect(contact).to(
        receive(:assignable_adoption_date=).with(
          assignable_instructor.external_ids.map(&:created_at).min.strftime('%Y-%m-%d')
        ).and_call_original
      )
      expect(contact).to receive(:save!)

      described_class.call

      expect(contact.assignable_interest).to eq 'Fully Integrated'
    end
  end

  context 'Contact not yet Fully Integrated' do
    it 'promotes a Contact with no prior Assignable interest' do
      contact = build_contact(id: 'TESTCONTACT2')
      stub_found_contacts('TESTCONTACT2' => contact)

      expect(contact).to receive(:assignable_interest=).with('Fully Integrated').and_call_original
      expect(contact).to(
        receive(:assignable_adoption_date=).with(
          assignable_instructor.external_ids.map(&:created_at).min.strftime('%Y-%m-%d')
        ).and_call_original
      )
      expect(contact).to receive(:save!)

      described_class.call
    end

    it 'promotes a Contact currently at Interested' do
      contact = build_contact(id: 'TESTCONTACT2', assignable_interest: 'Interested')
      stub_found_contacts('TESTCONTACT2' => contact)

      expect(contact).to receive(:assignable_interest=).with('Fully Integrated').and_call_original
      expect(contact).to receive(:save!)

      described_class.call
    end
  end

  context 'one Contact fails to save' do
    let!(:second_assignable_instructor) do
      FactoryBot.create(:user, salesforce_contact_id: 'TESTCONTACT3').tap do |user|
        FactoryBot.create :external_id, user: user
      end
    end

    it 'reports the failure to Sentry and still saves the next Contact' do
      failing_contact = build_contact(id: 'TESTCONTACT2')
      passing_contact = build_contact(id: 'TESTCONTACT3')
      stub_found_contacts('TESTCONTACT2' => failing_contact, 'TESTCONTACT3' => passing_contact)

      error = Restforce::ErrorCode::FieldCustomValidationException.new('invalid picklist value')
      allow(failing_contact).to receive(:save!).and_raise(error)
      expect(passing_contact).to receive(:save!)

      expect(Sentry).to receive(:capture_exception).with(
        error, extra: { user_id: assignable_instructor.id, contact_id: 'TESTCONTACT2' }
      )

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

  def build_contact(id:, assignable_interest: nil, assignable_adoption_date: nil)
    OpenStax::Salesforce::Remote::Contact.new(
      id: id, assignable_interest: assignable_interest,
      assignable_adoption_date: assignable_adoption_date
    ).tap(&:clear_changes_information)
  end

  def stub_found_contacts(contacts_by_id)
    allow(OpenStax::Salesforce::Remote::Contact).to receive(:find) { |id| contacts_by_id[id] }
  end
end
