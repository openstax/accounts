require 'rails_helper'
require 'rake'

describe 'accounts:backfill_last_signed_in_at' do
  include_context 'rake'

  let!(:user_with_logins) { FactoryBot.create :user }
  let!(:user_without_logins) { FactoryBot.create :user }
  let!(:user_already_populated) do
    FactoryBot.create :user, last_signed_in_at: 1.year.ago
  end

  let!(:latest_login) do
    FactoryBot.create :security_log, user: user_with_logins, event_type: :sign_in_successful,
                                      created_at: 1.day.ago
  end

  before do
    FactoryBot.create :security_log, user: user_with_logins, event_type: :sign_in_successful,
                                      created_at: 1.week.ago
    FactoryBot.create :security_log, user: user_with_logins, event_type: :sign_in_failed,
                                      created_at: 1.hour.ago
    FactoryBot.create :security_log, user: user_already_populated, event_type: :sign_in_successful,
                                      created_at: 1.day.ago
  end

  it "fills last_signed_in_at from each user's latest sign_in_successful log" do
    subject.invoke

    expect(user_with_logins.reload.last_signed_in_at).to be_within(1.second).of latest_login.created_at
  end

  it 'ignores users with no sign_in_successful logs' do
    subject.invoke

    expect(user_without_logins.reload.last_signed_in_at).to be_nil
  end

  it 'leaves already-populated rows alone' do
    original_value = user_already_populated.last_signed_in_at

    subject.invoke

    expect(user_already_populated.reload.last_signed_in_at).to be_within(1.second).of original_value
  end

  it 'is idempotent' do
    subject.invoke
    subject.reenable
    expect { subject.invoke }.not_to(change { user_with_logins.reload.last_signed_in_at })
  end
end
