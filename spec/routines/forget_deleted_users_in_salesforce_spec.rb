require 'rails_helper'

describe ForgetDeletedUsersInSalesforce, type: :routine do
  let(:sfdc_client) { double('sfdc client') }
  let(:contact_id) { '003AAAAAAAAAAAAAAA' }
  let(:lead_id) { '00QAAAAAAAAAAAAAAA' }
  let(:individual_id) { '0PKAAAAAAAAAAAAAAA' }
  let(:queries) { [] }

  before do
    stub_sentry
    allow(Settings::Salesforce).to receive(:forget_deleted_users_enabled) { true }
    allow(ActiveForce).to receive(:sfdc_client).and_return(sfdc_client)
  end

  def deleted_user(**attrs)
    FactoryBot.create(:user, is_deleted: true, **attrs)
  end

  def stub_records(contacts: [], leads: [])
    allow(sfdc_client).to receive(:query) do |soql|
      queries << soql
      rows = soql.include?('FROM Contact') ? contacts : leads
      rows.map { |id, individual| { 'Id' => id, 'IndividualId' => individual } }
    end
  end

  def stub_batch(statuses = nil)
    flagged = []
    allow(sfdc_client).to receive(:batch) do |&block|
      subrequests = double('subrequests')
      allow(subrequests).to receive(:update) { |object, attrs| flagged << [object, attrs] }
      block.call(subrequests)
      Array(statuses || flagged.map { 204 }).map { |code| { 'statusCode' => code } }
    end
    flagged
  end

  context 'when the flag is off' do
    before { allow(Settings::Salesforce).to receive(:forget_deleted_users_enabled) { false } }

    it 'does not query or write Salesforce' do
      user = deleted_user(salesforce_contact_id: contact_id)
      expect(sfdc_client).not_to receive(:query)
      expect(sfdc_client).not_to receive(:batch)

      described_class.call

      expect(user.reload.salesforce_forgotten_at).to be_nil
    end
  end

  context 'a deleted user with a Contact' do
    let!(:user) { deleted_user(salesforce_contact_id: contact_id) }

    it 'sets ShouldForget on the Individual with raw API names and stamps the user' do
      stub_records(contacts: [[contact_id, individual_id]])
      flagged = stub_batch

      described_class.call

      expect(flagged).to eq([['Individual', { Id: individual_id, ShouldForget: true }]])
      expect(user.reload.salesforce_forgotten_at).to be_within(1.minute).of(Time.current)
    end

    it 'finds the Contact when the stored id is the 15-character form' do
      user.update_column(:salesforce_contact_id, contact_id[0, 15])
      stub_records(contacts: [[contact_id, individual_id]])
      stub_batch

      described_class.call

      expect(user.reload.salesforce_forgotten_at).not_to be_nil
    end

    it 'leaves the user unstamped when Salesforce rejects the update' do
      stub_records(contacts: [[contact_id, individual_id]])
      stub_batch([400])
      expect(Sentry).to receive(:capture_message).with(/Individual update failed for 1 records/, anything)

      described_class.call

      expect(user.reload.salesforce_forgotten_at).to be_nil
    end

    it 'leaves the user unstamped and reports when the Contact has no IndividualId' do
      stub_records(contacts: [[contact_id, nil]])
      expect(sfdc_client).not_to receive(:batch)
      expect(Sentry).to receive(:capture_message).with(/no IndividualId for 1 records/, anything)

      described_class.call

      expect(user.reload.salesforce_forgotten_at).to be_nil
    end

    it 'retries a user left unstamped on the next run' do
      stub_records(contacts: [[contact_id, nil]])
      described_class.call
      expect(user.reload.salesforce_forgotten_at).to be_nil

      stub_records(contacts: [[contact_id, individual_id]])
      stub_batch
      described_class.call

      expect(user.reload.salesforce_forgotten_at).not_to be_nil
    end

    it 'does not select a user already forgotten' do
      user.update_column(:salesforce_forgotten_at, 1.day.ago)
      expect(sfdc_client).not_to receive(:query)

      described_class.call
    end

    it 'unlinks a Contact Salesforce no longer has and writes a security log' do
      stub_records(contacts: [])
      expect(sfdc_client).not_to receive(:batch)

      described_class.call

      user.reload
      expect(user.salesforce_contact_id).to be_nil
      expect(user.salesforce_forgotten_at).to be_nil
      expect(SecurityLog.where(user: user, event_type: :salesforce_record_unlinked).count).to eq(1)
    end

    it 'does not select the user again once unlinked' do
      stub_records(contacts: [])
      described_class.call

      expect(sfdc_client).not_to receive(:query)
      described_class.call
    end
  end

  context 'a deleted user with a Lead that converted into their Contact' do
    let!(:user) { deleted_user(salesforce_contact_id: contact_id, salesforce_lead_id: lead_id) }

    it 'flags the shared Individual once' do
      stub_records(contacts: [[contact_id, individual_id]], leads: [[lead_id, individual_id]])
      flagged = stub_batch

      described_class.call

      expect(flagged.size).to eq(1)
      expect(user.reload.salesforce_forgotten_at).not_to be_nil
    end

    it 'does not stamp while one linked record has no Individual, but still flags the other' do
      stub_records(contacts: [[contact_id, individual_id]], leads: [[lead_id, nil]])
      flagged = stub_batch
      allow(Sentry).to receive(:capture_message)

      described_class.call

      expect(flagged.size).to eq(1)
      expect(user.reload.salesforce_forgotten_at).to be_nil
    end

    it 'stamps once the Lead is gone and the Contact is flagged' do
      stub_records(contacts: [[contact_id, individual_id]], leads: [])
      stub_batch

      described_class.call

      user.reload
      expect(user.salesforce_lead_id).to be_nil
      expect(user.salesforce_forgotten_at).not_to be_nil
    end
  end

  context 'several deleted users' do
    let(:other_individual_id) { '0PKBBBBBBBBBBBBBBB' }
    let!(:first) { deleted_user(salesforce_lead_id: lead_id) }
    let!(:second) { deleted_user(salesforce_lead_id: '00QBBBBBBBBBBBBBBB') }
    let!(:sharing) { deleted_user(salesforce_lead_id: '00QCCCCCCCCCCCCCCC') }

    it 'looks up each object once per batch and de-duplicates Individuals' do
      stub_records(leads: [[lead_id, individual_id], ['00QBBBBBBBBBBBBBBB', other_individual_id],
                           ['00QCCCCCCCCCCCCCCC', individual_id]])
      flagged = stub_batch
      described_class.call

      expect(queries.size).to eq(1)

      expect(flagged.map { |_, attrs| attrs[:Id] }).to contain_exactly(individual_id, other_individual_id)
      expect([first, second, sharing].map { |u| u.reload.salesforce_forgotten_at }).to all(be_present)
    end

    it 'isolates one failing Individual from the others' do
      stub_records(leads: [[lead_id, individual_id], ['00QBBBBBBBBBBBBBBB', other_individual_id],
                           ['00QCCCCCCCCCCCCCCC', individual_id]])
      stub_batch([400, 204])
      allow(Sentry).to receive(:capture_message)

      described_class.call

      expect(first.reload.salesforce_forgotten_at).to be_nil
      expect(sharing.reload.salesforce_forgotten_at).to be_nil
      expect(second.reload.salesforce_forgotten_at).not_to be_nil
    end

    it 'reports the lookup failure once and stops the run' do
      stub_const("#{described_class}::BATCH_SIZE", 1)
      allow(sfdc_client).to receive(:query).and_raise('sf is down')
      expect(Sentry).to receive(:capture_exception).once

      described_class.call

      expect(first.reload.salesforce_forgotten_at).to be_nil
    end
  end

  context 'users who are not pending' do
    it 'ignores live users, deleted users with no Salesforce link, and students\' Student__c links' do
      FactoryBot.create(:user, salesforce_contact_id: contact_id)
      FactoryBot.create(:user, is_deleted: false, salesforce_lead_id: lead_id)
      deleted_user
      deleted_user(salesforce_student_id: 'a0STUDENT0000001')
      expect(sfdc_client).not_to receive(:query)

      described_class.call
    end
  end
end
