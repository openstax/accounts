require 'spec_helper'

RSpec.describe UsersController, type: :controller do

  let!(:user) { FactoryGirl.create :user, :terms_agreed }
  let!(:temp_user) { FactoryGirl.create :temp_user }

  context 'GET show' do
    it 'renders the edit profile page' do
      controller.sign_in user
      get 'show'
      expect(response.status).to eq 200
    end
  end

  context 'PUT update' do
    it 'updates the user' do
      controller.sign_in user
      put 'update', user: {username: "my_new_username"}
      expect(response.status).to eq 302
      expect(user.reload.username).to eq "my_new_username"
    end
  end

  context 'GET register' do
    it 'renders the registration page' do
      controller.sign_in temp_user
      get 'register'
      expect(response.status).to eq 200
    end
  end

  context 'PUT register' do
    it 'registers the user' do
      expect(temp_user.is_temp?).to eq true
      contract_1 = FinePrint::Contract.first
      contract_2 = FinePrint::Contract.last

      controller.sign_in temp_user
      put 'register', register: {i_agree: true,
                                 username: "my_username",
                                 contract_1_id: contract_1.id,
                                 contract_2_id: contract_2.id}
      expect(response.status).to eq 302
      expect(temp_user.reload.is_temp?).to eq false
      expect(temp_user.username).to eq "my_username"
      expect(FinePrint.signed_contract?(temp_user, contract_1)).to eq true
      expect(FinePrint.signed_contract?(temp_user, contract_2)).to eq true
    end
  end

end
