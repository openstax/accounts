require 'rails_helper'

RSpec.describe UserFromSignupState, type: :routine do

  context 'an unsigned state' do
    let(:signup_state) { FactoryGirl.create :signup_state }

    it 'builds a user account' do
      user = UserFromSignupState[signup_state]
      expect(user).to be_valid
      expect(user.external_uuids).to be_empty
    end
  end

  context 'a signed state' do
    let(:signup_state) { FactoryGirl.create :signup_state, :signed, role: 'instructor' }

    it 'builds a user account with signed attributes' do
      user = UserFromSignupState[signup_state]
      expect(user).to be_valid
      expect(user.role).to eq('instructor')
      expect(user.external_uuids).not_to be_empty
      expect(user.external_uuids.first.uuid).to eq(signup_state.signed_data['external_user_uuid'])
      expect(user.signed_external_data).to eq(signup_state.signed_data)
    end

  end

end
