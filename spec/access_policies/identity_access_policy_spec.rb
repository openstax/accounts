require 'rails_helper'

RSpec.describe IdentityAccessPolicy do

  let!(:identity)  { FactoryGirl.create :identity }
  let!(:anon)      { AnonymousUser.instance }
  let!(:temp)      { FactoryGirl.create :temp_user }
  let!(:user)      { FactoryGirl.create :user }
  let!(:admin)     { FactoryGirl.create :user, :admin }
  let!(:app)       { FactoryGirl.create :doorkeeper_application }

  context 'new, reset_password' do
    it 'cannot be accessed by applications' do
      [:new, :reset_password].each do |action|
        expect(OSU::AccessPolicy.action_allowed?(action, app, identity)).to eq false
      end
    end

    it 'can be accessed by human users' do
      [:new, :reset_password].each do |action|
        expect(OSU::AccessPolicy.action_allowed?(action, anon, identity)).to eq true
        expect(OSU::AccessPolicy.action_allowed?(action, temp, identity)).to eq true
        expect(OSU::AccessPolicy.action_allowed?(action, user, identity)).to eq true
        expect(OSU::AccessPolicy.action_allowed?(action, admin, identity)).to eq true
      end
    end
  end

  context 'update' do
    it 'cannot be accessed by applications or unauthorized users' do
      expect(OSU::AccessPolicy.action_allowed?(:update, app, identity)).to eq false
      expect(OSU::AccessPolicy.action_allowed?(:update, anon, identity)).to eq false
      expect(OSU::AccessPolicy.action_allowed?(:update, temp, identity)).to eq false
      expect(OSU::AccessPolicy.action_allowed?(:update, user, identity)).to eq false
      expect(OSU::AccessPolicy.action_allowed?(:update, admin, identity)).to eq false
    end

    it 'can be accessed by authorized users' do
      expect(OSU::AccessPolicy.action_allowed?(:update, identity.user, identity)).to eq true
    end
  end

end
