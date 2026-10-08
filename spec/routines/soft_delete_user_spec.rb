require 'rails_helper'

describe SoftDeleteUser do

  let(:user) { FactoryBot.create(:user_with_emails) }

  it 'returns gracefully when user is nil' do
    expect { described_class.call(nil) }.not_to raise_error
  end

  it 'sets is_deleted on the user' do
    described_class.call(user)
    expect(user.reload.is_deleted).to eq(true)
  end

  it 'overwrites the user name fields and username' do
    described_class.call(user)
    user.reload
    expect(user.first_name).to eq('Deleted')
    expect(user.last_name).to eq('User')
    expect(user.username).to eq("deleted_user_#{user.id}")
  end

  it 'destroys identifying associations' do
    FactoryBot.create(:authentication, user: user, provider: 'google_oauth2')
    FactoryBot.create(:identity, user: user)
    FactoryBot.create(:application_user, user: user)
    FactoryBot.create(:external_id, user: user)

    described_class.call(user)
    user.reload

    expect(user.authentications).to be_empty
    expect(user.identity).to be_nil
    expect(user.application_users).to be_empty
    expect(user.contact_infos).to be_empty
    expect(user.email_addresses).to be_empty
    expect(user.external_ids).to be_empty
    expect(user.external_uuids).to be_empty
  end

  it 'destroys group memberships' do
    group = FactoryBot.create(:group)
    FactoryBot.create(:group_owner, user: user, group: group)
    FactoryBot.create(:group_member, user: user, group: group)

    described_class.call(user)
    user.reload

    expect(user.group_owners).to be_empty
    expect(user.group_members).to be_empty
  end

  it 'destroys security logs (which contain PII)' do
    user.security_logs.create!(event_type: SecurityLog.event_types.keys.first)
    expect(user.security_logs.count).to be > 0

    described_class.call(user)
    expect(user.reload.security_logs).to be_empty
  end

  it 'clears any pending account deletion token' do
    user.refresh_account_deletion_token
    user.save!

    described_class.call(user)
    user.reload

    expect(user.account_deletion_token).to be_nil
    expect(user.account_deletion_token_expires_at).to be_nil
  end

  it 'clears profile fields a user typed in themselves' do
    user.update!(
      title: 'Dr.', suffix: 'Jr.', phone_number: '555-0100',
      self_reported_school: 'Somewhere College', other_role_name: 'Librarian',
      login_token: 'abc', login_token_expires_at: 1.day.from_now
    )

    described_class.call(user)
    user.reload

    expect([user.title, user.suffix, user.phone_number, user.self_reported_school,
            user.other_role_name, user.login_token]).to all(be_nil)
  end

  it 'destroys the stored SheerID verification' do
    verification = FactoryBot.create(:sheerid_verification)
    user.update!(sheerid_verification_id: verification.verification_id)

    described_class.call(user)

    expect(SheeridVerification.exists?(verification.id)).to eq(false)
  end
end
