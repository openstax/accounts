require 'rails_helper'

RSpec.describe TransferPreAuthState, type: :routine do

  it 'works on the happy path' do
    user = FactoryBot.create :user
    ss = FactoryBot.create :pre_auth_state, :contact_info_verified, role: "designer"

    TransferPreAuthState[pre_auth_state: ss, user: user]

    expect(user.contact_infos.reload.size).to eq 1
    expect(user.role).to eq "designer"

    expect{ss.reload}.to raise_error(ActiveRecord::RecordNotFound)
  end

  it 'does not transfer unverified info' do
    user = FactoryBot.create :user
    ss = FactoryBot.create :pre_auth_state
    TransferPreAuthState.call(pre_auth_state: ss, user: user)
    email = user.contact_infos.first
    expect(email.verified).to be(false)
  end

  it 'does not explode when the user already has a signed_external_uuid' do
    user = FactoryBot.create :user
    user.external_uuids.create(uuid: SecureRandom.uuid)
    ss = FactoryBot.create :pre_auth_state, :contact_info_verified, role: "designer",
                            signed_data: { 'external_user_uuid' => SecureRandom.uuid }

    TransferPreAuthState[pre_auth_state: ss, user: user]

    expect(user.contact_infos.reload.size).to eq 1
    expect(user.role).to eq "designer"

    expect{ss.reload}.to raise_error(ActiveRecord::RecordNotFound)

    expect(user.external_uuids.count).to eq 2
  end

end
