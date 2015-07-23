require 'spec_helper'

RSpec.describe Admin::UsersController do
  let!(:user) { FactoryGirl.create :user }

  describe 'PUT #update' do
    it 'updates a user' do
      put :update, id: user.id,
                   user: {
                     first_name: 'Malik',
                     last_name: 'Kristensen',
                     full_name: 'Malik A. Kristensen',
                     email_address: 'malik@example.org',
                     is_administrator: '1'
                   }
      user.reload
      expect(user.first_name).to eq 'Malik'
      expect(user.last_name).to eq 'Kristensen'
      expect(user.full_name).to eq 'Malik A. Kristensen'
      expect(user.email_addresses.first.value).to eq 'malik@example.org'
      expect(user.is_administrator).to be true
    end
  end
end
