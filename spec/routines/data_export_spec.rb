require 'rails_helper'

describe DataExport do

  let(:user) { FactoryBot.create(:user_with_emails, emails_count: 2) }

  it 'returns gracefully when user is nil' do
    outcome = described_class.call(nil)
    expect(outcome.errors.first.code).to eq(:no_user)
  end

  it 'exports the core profile fields' do
    data = described_class.call(user).outputs.data
    expect(data[:profile]).to include(
      uuid: user.uuid,
      username: user.username,
      first_name: user.first_name,
      last_name: user.last_name,
      role: user.role
    )
  end

  it 'exports contact infos including verification state' do
    user.contact_infos.first.update!(verified: true)
    data = described_class.call(user).outputs.data
    expect(data[:contact_infos].size).to eq(2)
    expect(data[:contact_infos].first).to include(:type, :value, :verified)
  end

  it 'exports authentications with provider only - no uid or credentials' do
    FactoryBot.create(:authentication, user: user, provider: 'google_oauth2', uid: 'secret-uid-123')
    data = described_class.call(user).outputs.data
    auth = data[:authentications].first
    expect(auth).to include(provider: 'google_oauth2')
    expect(auth.keys).not_to include(:uid)
    expect(auth.values).not_to include('secret-uid-123')
  end

  it 'exports school name when present' do
    data = described_class.call(user).outputs.data
    expect(data[:school]).to include(name: user.school.name)
  end

  it 'omits school when user has none' do
    user.update!(school: nil)
    data = described_class.call(user).outputs.data
    expect(data[:school]).to be_nil
  end

  it 'includes an exported_at timestamp' do
    data = described_class.call(user).outputs.data
    expect(data[:exported_at]).to match(/\A\d{4}-\d{2}-\d{2}T/)
  end
end
