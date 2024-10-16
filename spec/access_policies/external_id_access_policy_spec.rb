require 'rails_helper'

describe ExternalIdAccessPolicy do
  let!(:anon)        { AnonymousUser.instance }
  let!(:temp)        { FactoryBot.create :temp_user }
  let!(:user)        { FactoryBot.create :user }
  let!(:new_social)  { FactoryBot.create :new_social_user }
  let!(:admin)       { FactoryBot.create :user, :admin }
  let!(:app)         { FactoryBot.create :doorkeeper_application }
  let!(:trusted_app) { FactoryBot.create :doorkeeper_application, :trusted }

  let(:external_id)  { FactoryBot.create :external_id }

  context 'create' do
    it 'cannot be accessed by users or untrusted apps' do
      expect(OSU::AccessPolicy.action_allowed?(:create, anon, external_id)).to eq false
      expect(OSU::AccessPolicy.action_allowed?(:create, temp, external_id)).to eq false
      expect(OSU::AccessPolicy.action_allowed?(:create, user, external_id)).to eq false
      expect(OSU::AccessPolicy.action_allowed?(:create, new_social, external_id)).to eq false
      expect(OSU::AccessPolicy.action_allowed?(:create, admin, external_id)).to eq false
      expect(OSU::AccessPolicy.action_allowed?(:create, app, external_id)).to eq false
    end

    it 'can be accessed by trusted apps' do
      expect(OSU::AccessPolicy.action_allowed?(:create, trusted_app, external_id)).to eq true
    end
  end
end
