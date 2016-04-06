require 'rails_helper'

RSpec.describe 'RegistrationController', type: :controller do

  let!(:temp_user) { FactoryGirl.create :temp_user }

  # TODO find a new home for relevant pieces of below

  xcontext 'PUT complete' do
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
