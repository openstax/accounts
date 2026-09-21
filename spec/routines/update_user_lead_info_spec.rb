require 'rails_helper'

describe UpdateUserLeadInfo, type: :routine do
  before { stub_sentry }

  it 'skips switched student leads so reconcile does not overwrite the marker' do
    switched_user = FactoryBot.create(
      :user,
      role: User::STUDENT_ROLE,
      faculty_status: User::REJECTED_FACULTY,
      salesforce_lead_id: 'SF_LEAD_123',
      uuid: 'switched-user-uuid'
    )
    other_user = FactoryBot.create(
      :user,
      role: User::INSTRUCTOR_ROLE,
      faculty_status: User::INCOMPLETE_SIGNUP,
      salesforce_lead_id: 'SF_LEAD_456',
      uuid: 'other-user-uuid'
    )
    lead = instance_double(
      OpenStax::Salesforce::Remote::Lead,
      id: 'SF_LEAD_456',
      accounts_uuid: other_user.uuid,
      verification_status: 'confirmed_faculty'
    )
    relation = double('lead relation')

    allow(OpenStax::Salesforce::Remote::Lead).to receive(:select)
      .with(:id, :accounts_uuid, :verification_status)
      .and_return(relation)
    expect(relation).to receive(:where).with(accounts_uuid: [other_user.uuid]).and_return([lead])

    described_class.call

    expect(switched_user.reload.faculty_status).to eq(User::REJECTED_FACULTY)
    expect(other_user.reload.faculty_status).to eq(User::CONFIRMED_FACULTY)
  end
end
