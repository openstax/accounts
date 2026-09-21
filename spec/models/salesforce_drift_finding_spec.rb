require 'rails_helper'

RSpec.describe SalesforceDriftFinding do
  let(:user) { FactoryBot.create(:user) }

  it 'is valid with category and timestamps' do
    f = described_class.new(
      category: 'sf_orphan_contact',
      first_seen_at: Time.current,
      last_seen_at: Time.current
    )
    expect(f).to be_valid
  end

  it 'belongs to a user optionally' do
    f = FactoryBot.create(:salesforce_drift_finding, user: user)
    expect(f.user).to eq(user)
  end

  it 'requires category' do
    f = described_class.new(first_seen_at: Time.current, last_seen_at: Time.current)
    expect(f).not_to be_valid
  end

  describe 'scopes' do
    let!(:open_f)     { FactoryBot.create(:salesforce_drift_finding, resolved_at: nil) }
    let!(:resolved_f) { FactoryBot.create(:salesforce_drift_finding, resolved_at: 1.day.ago) }

    it '.open returns only unresolved findings' do
      expect(described_class.open).to contain_exactly(open_f)
    end

    it '.resolved returns only resolved' do
      expect(described_class.resolved).to contain_exactly(resolved_f)
    end
  end

  describe '.upsert_finding!' do
    it 'creates when no matching open finding exists' do
      expect {
        described_class.upsert_finding!(
          user: user, category: 'sf_orphan_contact',
          record_type: 'Contact', record_id: 'C1'
        )
      }.to change(described_class, :count).by(1)
    end

    it 'updates last_seen_at when a matching open finding exists' do
      existing = FactoryBot.create(:salesforce_drift_finding,
        user: user, category: 'sf_orphan_contact',
        salesforce_record_type: 'Contact', salesforce_record_id: 'C1',
        last_seen_at: 2.days.ago, resolved_at: nil)
      described_class.upsert_finding!(
        user: user, category: 'sf_orphan_contact',
        record_type: 'Contact', record_id: 'C1'
      )
      expect(existing.reload.last_seen_at).to be_within(2.seconds).of(Time.current)
    end

    it 'creates a new one when the prior matching finding was resolved' do
      FactoryBot.create(:salesforce_drift_finding,
        user: user, category: 'sf_orphan_contact',
        salesforce_record_type: 'Contact', salesforce_record_id: 'C1',
        resolved_at: 1.day.ago)
      expect {
        described_class.upsert_finding!(
          user: user, category: 'sf_orphan_contact',
          record_type: 'Contact', record_id: 'C1'
        )
      }.to change(described_class, :count).by(1)
    end
  end

  describe '#resolve!' do
    it 'sets resolved_at' do
      f = FactoryBot.create(:salesforce_drift_finding, resolved_at: nil)
      expect { f.resolve! }.to change { f.reload.resolved_at }.from(nil)
    end
  end
end
