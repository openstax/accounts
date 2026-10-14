require 'rails_helper'
require 'rake'

describe 'accounts:backfill_last_seen_at' do
  include_context 'rake'

  let(:login_time) { 2.days.ago }
  let!(:user_with_login) { FactoryBot.create :user, last_signed_in_at: login_time }
  let!(:user_without_login) { FactoryBot.create :user, last_signed_in_at: nil, last_seen_at: nil }
  let!(:user_already_populated) do
    FactoryBot.create :user, last_signed_in_at: 2.days.ago, last_seen_at: 1.day.ago
  end

  it 'fills last_seen_at from last_signed_in_at' do
    subject.invoke

    expect(user_with_login.reload.last_seen_at).to be_within(1.second).of login_time
  end

  it 'leaves users with no last_signed_in_at alone' do
    subject.invoke

    expect(user_without_login.reload.last_seen_at).to be_nil
  end

  it 'leaves already-populated rows alone' do
    original_value = user_already_populated.last_seen_at

    subject.invoke

    expect(user_already_populated.reload.last_seen_at).to be_within(1.second).of original_value
  end

  it 'is idempotent' do
    subject.invoke
    subject.reenable
    expect { subject.invoke }.not_to(change { user_with_login.reload.last_seen_at })
  end
end
