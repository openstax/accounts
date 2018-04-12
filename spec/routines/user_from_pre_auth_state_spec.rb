require 'rails_helper'

RSpec.describe UserFromPreAuthState, type: :routine do

  context 'an unsigned state' do
    let(:pre_auth_state) { FactoryGirl.create :pre_auth_state }

    it 'builds a user account' do
      user = UserFromPreAuthState[pre_auth_state]
      expect(user).to be_valid
      expect(user.external_uuids).to be_empty
    end
  end

  context 'a signed state' do
    let(:pre_auth_state) { FactoryGirl.create :pre_auth_state, :signed, role: 'instructor' }

    it 'builds a user account with signed attributes' do
      user = UserFromPreAuthState[pre_auth_state]
      expect(user).to be_valid
      expect(user.role).to eq('instructor')
      expect(user.external_uuids).not_to be_empty
      expect(user.external_uuids.first.uuid).to eq(pre_auth_state.signed_data['external_user_uuid'])
      expect(user.signed_external_data).to eq(pre_auth_state.signed_data)
    end

  end

end
