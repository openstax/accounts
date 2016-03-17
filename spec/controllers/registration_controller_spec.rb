require 'rails_helper'

RSpec.describe RegistrationController, type: :controller do

  let!(:temp_user) { FactoryGirl.create :temp_user }

  xcontext 'GET complete' do
    it 'renders the registration page' do
      controller.sign_in! temp_user
      get :complete
      expect(response.status).to eq 200
    end
  end

  xcontext 'PUT complete' do
    it 'registers the user' do
      expect(temp_user.is_temp?).to eq true
      contract_1 = FinePrint::Contract.first
      contract_2 = FinePrint::Contract.last

      controller.sign_in! temp_user
      put :complete, register: {i_agree: true,
                                 first_name: 'My',
                                 last_name: 'Username',
                                 username: "my_username",
                                 contract_1_id: contract_1.id,
                                 contract_2_id: contract_2.id}
      expect(response.status).to eq 302
      expect(temp_user.reload.is_temp?).to eq false
      expect(temp_user.username).to eq "my_username"
      expect(FinePrint.signed_contract?(temp_user, contract_1)).to eq true
      expect(FinePrint.signed_contract?(temp_user, contract_2)).to eq true
    end

    it 'registers the user with all the details' do
      expect(temp_user.is_temp?).to eq true
      contract_1 = FinePrint::Contract.first
      contract_2 = FinePrint::Contract.last

      controller.sign_in! temp_user
      put :complete, register: {i_agree: true,
                                 title: 'Dr',
                                 username: "my_username",
                                 first_name: 'First',
                                 last_name: 'Last',
                                 suffix: 'Junior',
                                 contract_1_id: contract_1.id,
                                 contract_2_id: contract_2.id}
      expect(response.status).to eq 302
      expect(temp_user.reload.is_temp?).to eq false
      expect(temp_user.username).to eq "my_username"
      expect(temp_user.title).to eq 'Dr'
      expect(temp_user.first_name).to eq 'First'
      expect(temp_user.last_name).to eq 'Last'
      expect(temp_user.suffix).to eq 'Junior'
      expect(FinePrint.signed_contract?(temp_user, contract_1)).to eq true
      expect(FinePrint.signed_contract?(temp_user, contract_2)).to eq true
    end

    it "claims an unclaimed account" do
      user = FactoryGirl.create :user, state: 'unclaimed'
      expect(user.state).to eq 'unclaimed'
      controller.sign_in! user
      contract_1 = FinePrint::Contract.first
      contract_2 = FinePrint::Contract.last
      put :complete, register: {i_agree: true,
                                 first_name: 'My',
                                 last_name: 'Username',
                                 username: "my_username",
                                 contract_1_id: contract_1.id,
                                 contract_2_id: contract_2.id}
      expect(user.reload.state).to eq 'activated'
    end
  end

end
