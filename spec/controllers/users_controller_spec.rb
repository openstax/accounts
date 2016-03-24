require 'rails_helper'

RSpec.describe UsersController, type: :controller do

  let!(:user) { FactoryGirl.create :user, :terms_agreed }

  context 'GET edit' do
    it 'renders the edit profile page' do
      controller.sign_in! user
      get 'edit'
      expect(response.status).to eq 200
    end
  end

  context 'PUT update' do
    it "updates the user's profile" do
      controller.sign_in! user
      put 'update', {
        name: 'username',
        value: 'newusername',
        format: 'json'
      }
      expect(response.status).to eq 200
      expect(user.reload.username).to eq "newusername"
    end

    it "updates the user's profile for all fields" do
      controller.sign_in! user
      put 'update', {
        name: 'name',
        value: {
          title: 'Dr',
          first_name: 'NewFirst',
          last_name: 'NewLast',
          suffix: 'NewSuffix'
        },
        format: 'json'
      }
      expect(response.status).to eq 200
      user.reload
      expect(user.title).to eq 'Dr'
      expect(user.first_name).to eq 'NewFirst'
      expect(user.last_name).to eq 'NewLast'
      expect(user.suffix).to eq 'NewSuffix'
      expect(user.full_name).to eq 'Dr NewFirst NewLast NewSuffix'
    end
  end

end
