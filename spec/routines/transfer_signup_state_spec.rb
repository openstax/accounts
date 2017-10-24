require 'rails_helper'

describe TransferSignupState do

  it 'works on the happy path' do
    user = FactoryGirl.create :user
    ss = FactoryGirl.create :signup_state, :verified, role: "designer"

    TransferSignupState[signup_state: ss, user: user]

    expect(user.contact_infos(true).size).to eq 1
    expect(user.role).to eq "designer"

    expect{ss.reload}.to raise_error(ActiveRecord::RecordNotFound)
  end

  it 'does not transfer unverified info' do
    user = FactoryGirl.create :user
    ss = FactoryGirl.create :signup_state
    TransferSignupState.call(signup_state: ss, user: user)
    email = user.contact_infos.first
    expect(email.verified).to be(false)
  end

end
