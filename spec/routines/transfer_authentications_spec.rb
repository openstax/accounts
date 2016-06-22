require 'rails_helper'

describe TransferAuthentications do
  let(:target_user) { FactoryGirl.create :temp_user, username: 'target_user' }
  let(:other_user) { FactoryGirl.create :temp_user, username: 'other_user'}
  let(:authentication) { FactoryGirl.create :authentication, user: other_user, provider: 'google' }
  let(:authentication2) { FactoryGirl.create :authentication, user: nil, provider: 'facebook' }

  it 'transfers an authentication to the target user' do
    TransferAuthentications.call(authentication, target_user)
    expect(authentication.reload.user).to eq(target_user)
  end

  it 'transfers a list of authentications to the target user' do
    TransferAuthentications.call([authentication, authentication2], target_user)
    expect(authentication.reload.user).to eq(target_user)
    expect(authentication2.reload.user).to eq(target_user)
  end

  it 'deletes users that have no authentications' do
    TransferAuthentications.call(authentication, target_user)
    expect(User.exists?(other_user.id)).to be_falsey
  end
end
