require 'rails_helper'

RSpec.describe ContactInfoAccessPolicy do

  let!(:contact_info) { FactoryBot.create :email_address }
  let!(:anon)         { AnonymousUser.instance }
  let!(:temp)         { FactoryBot.create :temp_user }
  let!(:user)         { FactoryBot.create :user }
  let!(:admin)        { FactoryBot.create :user, :admin }
  let!(:app)          { FactoryBot.create :doorkeeper_application }

  context 'read, create, destroy, set_searchable, resend_confirmation' do
    it 'cannot be accessed by applications or unauthorized users' do
      [:read, :create, :update].each do |act|
        expect(OSU::AccessPolicy.action_allowed?(act, app,
                                                 contact_info)).to eq false
        expect(OSU::AccessPolicy.action_allowed?(act, anon,
                                                 contact_info)).to eq false
        expect(OSU::AccessPolicy.action_allowed?(act, temp,
                                                 contact_info)).to eq false
        expect(OSU::AccessPolicy.action_allowed?(act, user,
                                                 contact_info)).to eq false
        expect(OSU::AccessPolicy.action_allowed?(act, admin,
                                                 contact_info)).to eq false
      end
    end

    it "can be accessed by the contact info's owner" do
      [:read, :create, :destroy].each do |act|
        expect(OSU::AccessPolicy.action_allowed?(act, contact_info.user,
                                                 contact_info)).to eq true
      end
    end
  end

end
