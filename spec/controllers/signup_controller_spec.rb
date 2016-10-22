require "rails_helper"

RSpec.describe SignupController, type: :controller do

  before(:all) { load 'db/seeds.rb' }

  let(:params) do
    {
      signup: {
        i_agree: true,
        username: 'sheep',
        title: 'Miss',
        first_name: 'Little',
        last_name: 'Sheep',
        email_address: 'sheep@example.org',
        contract_1_id: FinePrint::Contract.first.id, # rspec spec --seed 39569 fails here
        contract_2_id: FinePrint::Contract.last.id }
    }
  end

  let(:user) { FactoryGirl.create :temp_user }
  let!(:authentication) { FactoryGirl.create :authentication, user: user }

  context "POST social" do
    it "creates a new user with a social network and redirects on success" do
      controller.sign_in! user
      post :social, params

      expect(response).to redirect_to root_path
    end

    it "redirects to login page if user is not logged in" do
      post :social, params

      expect(response).to redirect_to signin_path
    end
  end

end
