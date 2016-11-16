require "rails_helper"

RSpec.describe SignupController, type: :controller do

  # For whatever reason, before(:all) here is glitchy and sometimes deletes the contracts
  # on rollback between examples, so we create them for each example instead
  before(:each) do
    load 'db/seeds.rb'

    @contract_1 = FinePrint::Contract.first
    @contract_2 = FinePrint::Contract.last
  end

  let(:params) do
    {
      signup: {
        i_agree: true,
        username: 'sheep',
        title: 'Miss',
        first_name: 'Little',
        last_name: 'Sheep',
        email_address: 'sheep@example.org',
        contract_1_id: @contract_1.id,
        contract_2_id: @contract_2.id }
    }
  end

  let(:user)            { FactoryGirl.create :temp_user }
  let!(:authentication) { FactoryGirl.create :authentication, user: user }

  xcontext "POST social" do
    it "creates a new user with a social network and redirects on success" do
      controller.sign_in! user
      post :social, params

      expect(response).to redirect_to root_path
    end

    it "redirects to login page if user is not logged in" do
      post :social, params

      expect(response).to redirect_to login_path
    end
  end

end
