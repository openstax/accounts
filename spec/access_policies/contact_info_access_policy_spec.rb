require 'spec_helper'

RSpec.describe ContactInfoAccessPolicy do

  let!(:contact_info) { FactoryGirl.create :email_address }
  let!(:anon)         { AnonymousUser.instance }
  let!(:temp)         { FactoryGirl.create :temp_user }
  let!(:user)         { FactoryGirl.create :user }
  let!(:admin)        { FactoryGirl.create :user, :admin }
  let!(:app)          { FactoryGirl.create :doorkeeper_application }

  context 'read, create, destroy, resend_confirmation' do
    it 'cannot be accessed by applications or unauthorized users' do
      [:read, :create, :destroy, :resend_confirmation].each do |action|
        expect(OSU::AccessPolicy.action_allowed?(action, app, contact_info)).to eq false
        expect(OSU::AccessPolicy.action_allowed?(action, anon, contact_info)).to eq false
        expect(OSU::AccessPolicy.action_allowed?(action, temp, contact_info)).to eq false
        expect(OSU::AccessPolicy.action_allowed?(action, user, contact_info)).to eq false
        expect(OSU::AccessPolicy.action_allowed?(action, admin, contact_info)).to eq false
      end
    end

    it "can be accessed by the contact info's owner" do
      [:read, :create, :destroy, :resend_confirmation].each do |action|
        expect(OSU::AccessPolicy.action_allowed?(action, contact_info.user,
                                                 contact_info)).to eq true
      end
    end
  end

  context 'confirm' do
    it 'cannot be accessed by applications' do
      expect(OSU::AccessPolicy.action_allowed?(:confirm, app, contact_info)).to eq false
    end

    it 'can be accessed by anyone else' do
      expect(OSU::AccessPolicy.action_allowed?(:confirm, anon, contact_info)).to eq true
      expect(OSU::AccessPolicy.action_allowed?(:confirm, temp, contact_info)).to eq true
      expect(OSU::AccessPolicy.action_allowed?(:confirm, user, contact_info)).to eq true
      expect(OSU::AccessPolicy.action_allowed?(:confirm, admin, contact_info)).to eq true
    end
  end

end
