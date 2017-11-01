require 'rails_helper'

describe UserFromSignupState do

  context 'an untrusted state' do
    let(:signup_state) { FactoryGirl.create :signup_state }

    it 'builds a user account' do
      user = UserFromSignupState[signup_state]
      expect(user).to be_valid
      expect(user.external_uuids).to be_empty
    end
  end

  context 'a trusted state' do
    let(:signup_state) { FactoryGirl.create :signup_state, :trusted, role: 'instructor' }

    it 'builds a user account with attributes set from tusted' do
      user = UserFromSignupState[signup_state]
      expect(user).to be_valid
      expect(user.role).to eq('instructor')
      expect(user.external_uuids.first.uuid).to eq(signup_state.trusted_data['external_user_uuid'])
      expect(user.trusted_signup_data).to eq(signup_state.trusted_data)
    end

  end

end
