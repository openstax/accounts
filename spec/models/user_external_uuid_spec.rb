require 'rails_helper'

RSpec.describe UserExternalUuid, type: :model do

  let(:user) { FactoryBot.create :user }

  it 'links to user' do
    expect(user.external_uuids.create(uuid: SecureRandom.uuid)).to_not be_nil
    expect(user.external_uuids.first.user).to be(user)
  end
end
