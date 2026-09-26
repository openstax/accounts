require 'rails_helper'
require 'rake'

describe 'accounts:repush_incomplete_signup_leads' do
  include_context 'rake'

  def stub_stale_leads(*pages)
    relation = double('lead relation')
    allow(relation).to receive(:where).and_return(relation)
    allow(relation).to receive(:order).and_return(relation)
    allow(relation).to receive(:limit).and_return(relation)
    allow(OpenStax::Salesforce::Remote::Lead).to receive(:select).and_return(relation)

    call_count = 0
    allow(relation).to receive(:to_a) do
      page = pages[call_count] || []
      call_count += 1
      page
    end
  end

  def build_lead(uuid:, lead_id: 'SF_LEAD_001')
    OpenStax::Salesforce::Remote::Lead.new(id: lead_id, accounts_uuid: uuid)
  end

  before { stub_sentry }

  it 'pushes a lead for a user whose status has moved past incomplete_signup' do
    user = FactoryBot.create :user, faculty_status: :confirmed_faculty, uuid: 'uuid-confirmed'
    lead = build_lead(uuid: user.uuid, lead_id: 'SF_LEAD_CONFIRMED')
    stub_stale_leads([lead])

    expect(Newflow::CreateOrUpdateSalesforceLead).to receive(:call).with(user: user)

    subject.invoke
  end

  it 'skips a user still at or below incomplete_signup' do
    user = FactoryBot.create :user, faculty_status: :incomplete_signup, uuid: 'uuid-still-incomplete'
    lead = build_lead(uuid: user.uuid)
    stub_stale_leads([lead])

    expect(Newflow::CreateOrUpdateSalesforceLead).not_to receive(:call)

    subject.invoke
  end

  it 'skips a lead with no matching Accounts user' do
    lead = build_lead(uuid: 'no-such-uuid')
    stub_stale_leads([lead])

    expect(Newflow::CreateOrUpdateSalesforceLead).not_to receive(:call)

    subject.invoke
  end

  it 'does not push anything under DRY_RUN, but still counts it as pushable' do
    user = FactoryBot.create :user, faculty_status: :confirmed_faculty, uuid: 'uuid-dry-run'
    lead = build_lead(uuid: user.uuid)
    stub_stale_leads([lead])
    stub_const('ENV', ENV.to_hash.merge('DRY_RUN' => 'true'))

    expect(Newflow::CreateOrUpdateSalesforceLead).not_to receive(:call)
    subject.invoke
  end

  it 'reports a failed push to Sentry and keeps counting the rest' do
    bad_user = FactoryBot.create :user, faculty_status: :confirmed_faculty, uuid: 'uuid-bad'
    good_user = FactoryBot.create :user, faculty_status: :confirmed_faculty, uuid: 'uuid-good'
    bad_lead = build_lead(uuid: bad_user.uuid, lead_id: 'BAD')
    good_lead = build_lead(uuid: good_user.uuid, lead_id: 'GOOD')
    stub_stale_leads([bad_lead, good_lead])

    allow(Newflow::CreateOrUpdateSalesforceLead).to receive(:call) do |user:|
      raise StandardError, 'salesforce is down' if user == bad_user
    end

    expect(Sentry).to receive(:capture_exception).with(
      instance_of(StandardError), extra: { user_id: bad_user.id, salesforce_lead_id: 'BAD' }
    )

    expect { subject.invoke }.not_to raise_error
  end
end
