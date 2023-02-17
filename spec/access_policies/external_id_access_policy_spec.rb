require 'rails_helper'

RSpec.describe ExternalIdAccessPolicy do
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
      expect(OSU::AccessPolicy.action_allowed?(:search, anon, external_id)).to eq false
      expect(OSU::AccessPolicy.action_allowed?(:search, temp, external_id)).to eq false
      expect(OSU::AccessPolicy.action_allowed?(:search, user, external_id)).to eq false
      expect(OSU::AccessPolicy.action_allowed?(:search, new_social, external_id)).to eq false
      expect(OSU::AccessPolicy.action_allowed?(:search, admin, external_id)).to eq false
      expect(OSU::AccessPolicy.action_allowed?(:search, app, external_id)).to eq false
    end

    it 'can be accessed by trusted apps' do
      expect(OSU::AccessPolicy.action_allowed?(:search, trusted_app, User)).to eq true
    end
  end
end