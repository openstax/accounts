require "spec_helper"

describe Api::V1::UsersController, :type => :api, :version => :v1 do

  describe "GET" do

    let!(:application) { FactoryGirl.create :doorkeeper_application }
    let!(:user)        { FactoryGirl.create :user }
    let!(:token)       { FactoryGirl.create :doorkeeper_access_token, 
                                              application: application, 
                                              resource_owner_id: user.id }

    it "should GET a User " do
      debugger
      request.env['BLAH'] = 'JP'
      api_get :show, token, {id: 1}
      expect(response.code).to eq('200')
    end

  end

end
