require 'rails_helper'

RSpec.describe Salesforce::Metrics do
  before do
    allow(Sentry).to receive(:capture_check_in).and_return('check_in_id')
    allow(Sentry).to receive(:capture_message)
  end

  describe '#increment' do
    it 'accumulates integer counters' do
      m = described_class.new(run: 'sync_contacts')
      m.increment(:users_updated)
      m.increment(:users_updated, by: 2)
      expect(m.counters[:users_updated]).to eq(3)
    end

    it 'labels sub-counters by keyword and tracks a total' do
      m = described_class.new(run: 'sync_contacts')
      m.increment(:contact_id_swaps, reason: :merged)
      m.increment(:contact_id_swaps, reason: :merged)
      m.increment(:contact_id_swaps, reason: :gone)
      expect(m.counters[:contact_id_swaps]).to eq(total: 3, merged: 2, gone: 1)
    end
  end

  describe '#start! and #emit' do
    it 'opens and closes a Sentry check-in when a slug is given' do
      m = described_class.new(run: 'sync_contacts', slug: 'update-user-contact-info')
      expect(Sentry).to receive(:capture_check_in).with('update-user-contact-info', :in_progress)
      m.start!
      expect(Sentry).to receive(:capture_check_in).with('update-user-contact-info', :ok, hash_including(:check_in_id))
      m.emit(status: :ok)
    end

    it 'skips Sentry check-in when no slug' do
      m = described_class.new(run: 'sync_contacts')
      expect(Sentry).not_to receive(:capture_check_in)
      m.start!
      m.emit
    end

    it 'returns the payload from emit' do
      m = described_class.new(run: 'sync_contacts')
      m.increment(:users_updated, by: 5)
      payload = m.emit(status: :ok)
      expect(payload).to include(run: 'sync_contacts', status: :ok)
      expect(payload[:counters][:users_updated]).to eq(5)
      expect(payload[:duration_s]).to be_a(Integer)
    end
  end

  describe '#alert!' do
    it 'fires a Sentry message tagged with salesforce-alert' do
      m = described_class.new(run: 'sync_contacts')
      m.alert!(:contact_id_swap_rate_high, value: 12.0, threshold: 5.0)
      expect(Sentry).to have_received(:capture_message)
        .with(/contact_id_swap_rate_high/, hash_including(tags: hash_including('salesforce-alert' => 'contact_id_swap_rate_high')))
    end
  end
end
