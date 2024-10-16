require 'rails_helper'

describe UserAccessPolicy do

  let!(:anon)        { AnonymousUser.instance }
  let!(:temp)        { FactoryBot.create :temp_user }
  let!(:user)        { FactoryBot.create :user }
  let!(:new_social)  { FactoryBot.create :new_social_user }
  let!(:admin)       { FactoryBot.create :user, :admin }
  let!(:app)         { FactoryBot.create :doorkeeper_application }
  let!(:trusted_app) { FactoryBot.create :doorkeeper_application, :trusted }

  context 'search' do
    it 'cannot be accessed by anonymous or temp users' do
      expect(OSU::AccessPolicy.action_allowed?(:search, anon, User)).to eq false
      expect(OSU::AccessPolicy.action_allowed?(:search, temp, User)).to eq false
    end

    it 'can be accessed by non-temp users' do
      expect(OSU::AccessPolicy.action_allowed?(:search, user, User)).to eq true
      expect(OSU::AccessPolicy.action_allowed?(:search, admin, User)).to eq true
      expect(OSU::AccessPolicy.action_allowed?(:search, app, User)).to eq true
    end
  end

  context 'read, update' do
    it 'cannot be accessed by anonymous users or apps' do
      expect(OSU::AccessPolicy.action_allowed?(:read, anon, anon)).to eq false
      expect(OSU::AccessPolicy.action_allowed?(:read, app, user)).to eq false

      expect(OSU::AccessPolicy.action_allowed?(:update, anon, anon)).to eq false
      expect(OSU::AccessPolicy.action_allowed?(:update, app, user)).to eq false
    end

    it 'can be accessed by human users, temp or not' do
      expect(OSU::AccessPolicy.action_allowed?(:read, user, user)).to eq true
      expect(OSU::AccessPolicy.action_allowed?(:read, admin, admin)).to eq true
      expect(OSU::AccessPolicy.action_allowed?(:read, temp, temp)).to eq true

      expect(OSU::AccessPolicy.action_allowed?(:update, user, user)).to eq true
      expect(OSU::AccessPolicy.action_allowed?(:update, admin, admin)).to eq true
      expect(OSU::AccessPolicy.action_allowed?(:update, temp, temp)).to eq true
    end

    it 'cannot access other users unless admin' do
      expect(OSU::AccessPolicy.action_allowed?(:read, user, admin)).to eq false
      expect(OSU::AccessPolicy.action_allowed?(:read, admin, user)).to eq true

      expect(OSU::AccessPolicy.action_allowed?(:update, user, admin)).to eq false
      expect(OSU::AccessPolicy.action_allowed?(:update, admin, user)).to eq true
    end
  end

  context 'signup' do
    it 'cannot be accessed by activated users' do
      expect(OSU::AccessPolicy.action_allowed?(:signup, user, user)).to eq false
      expect(OSU::AccessPolicy.action_allowed?(:signup, admin, admin)).to eq false
    end

    it 'cannot be accessed by apps' do
      expect(OSU::AccessPolicy.action_allowed?(:signup, app, user)).to eq false
    end

    it 'can be accessed by temp users and new_social_users' do
      expect(OSU::AccessPolicy.action_allowed?(:signup, temp, temp)).to eq true  # deprecated check
      expect(OSU::AccessPolicy.action_allowed?(:signup, new_social, new_social)).to eq true
    end

    it 'cannot access other users' do
      expect(OSU::AccessPolicy.action_allowed?(:signup, temp, user)).to eq false
      expect(OSU::AccessPolicy.action_allowed?(:signup, new_social, user)).to eq false
      expect(OSU::AccessPolicy.action_allowed?(:signup, temp, admin)).to eq false
    end
  end

  [ :find, :create ].each do |action|
    context action do
      it 'cannot be accessed by users or unstrusted apps' do
        expect(OSU::AccessPolicy.action_allowed?(action, anon, anon)).to eq false
        expect(OSU::AccessPolicy.action_allowed?(action, temp, user)).to eq false
        expect(OSU::AccessPolicy.action_allowed?(action, user, user)).to eq false
        expect(OSU::AccessPolicy.action_allowed?(action, new_social, user)).to eq false
        expect(OSU::AccessPolicy.action_allowed?(action, admin, user)).to eq false
        expect(OSU::AccessPolicy.action_allowed?(action, app, user)).to eq false
      end

      it 'can be accessed by trusted apps' do
        expect(OSU::AccessPolicy.action_allowed?(action, trusted_app, user)).to eq true
      end
    end
  end

end
