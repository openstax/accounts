require 'rails_helper'

# TODO add specs for missing, but required, params
# TODO add in UsersRegister specs -- oops maybe are none?  then add specs to test rest of SignupProcess

describe SignupSocial, type: :handler do
  before(:all) { load 'db/seeds.rb' }

  let(:params) { {
    signup: {
      i_agree: true,
      username: 'sheep',
      title: 'Miss',
      first_name: 'Little',
      last_name: 'Sheep',
      email_address: '',
      contract_1_id: FinePrint::Contract.first.id,
      contract_2_id: FinePrint::Contract.last.id
    }
  } }

  let(:user) { FactoryGirl.create :temp_user }

  context 'email address' do
    it 'is required' do
      result = SignupSocial.call(caller: user, params: params)
      expect(result.errors.length).to be 1
      error = result.errors.first
      expect(error.code).to eq(:email_address_required)
      expect(error.message).to eq(
        'You must provide an email address to create your account.')
    end

    it 'is not required if the social network already provided one' do
      FactoryGirl.create :email_address, user: user

      result = SignupSocial.call(caller: user, params: params)
      expect(result.errors).to be_empty
    end

    it 'is ignored if the social network already provided one' do
      email = FactoryGirl.create :email_address, user: user
      params[:signup][:email_address] = 'sheep@example.org'

      result = SignupSocial.call(caller: user, params: params)
      expect(result.errors).to be_empty
      expect(user.reload.email_addresses).to eq([email])
    end
  end
end
