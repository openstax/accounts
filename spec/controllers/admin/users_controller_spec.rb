require 'rails_helper'

RSpec.describe Admin::UsersController, type: :controller do
  let!(:user) { FactoryGirl.create :user }
  let!(:identity) { FactoryGirl.create :identity, user: user }
  let(:admin) { FactoryGirl.create :user, :admin, :terms_agreed }

  before(:each) do
    controller.sign_in! admin
  end

  describe 'PUT #update' do
    it 'updates a user' do
      put :update, id: user.id,
                   user: {
                     first_name: 'Malik',
                     last_name: 'Kristensen',
                     email_address: 'malik@example.org',
                     is_administrator: '1',
                     faculty_status: 'rejected_faculty',
                     school_type: 'college',
                     password: 'si4eeSai',
                     password_confirmation: 'si4eeSai'
                   }
      user.reload
      expect(user.first_name).to eq 'Malik'
      expect(user.last_name).to eq 'Kristensen'
      expect(user.full_name).to eq 'Malik Kristensen'
      expect(user.email_addresses.first.value).to eq 'malik@example.org'
      expect(user).to be_is_administrator
      expect(user).to be_rejected_faculty
      expect(user).to be_college
      expect(user.identity.authenticate('si4eeSai')).to eq user.identity
    end
  end

  describe 'trusted lauch removal' do
    it 'removes all the external uuids' do
      user.external_uuids.create!({ uuid: SecureRandom.uuid })
      put :update, id: user.id,
          user: { keep_external_uuids: '0' }

      expect(user.external_uuids.reload.none?).to be true
    end
  end

  describe "PUT #mark_users_updated" do
    it "should update unread_updates at a button push" do
      FactoryGirl.create :application_user, unread_updates: 1
      FactoryGirl.create :application_user, unread_updates: 3

      put :mark_users_updated

      expect(ApplicationUser.all.map(&:unread_updates)).to contain_exactly(2,4)
    end
  end

end
