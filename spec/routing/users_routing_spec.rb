require 'rails_helper'

RSpec.describe Legacy::UsersController, :type => :routing do
  describe "routing" do

    it "routes to #edit" do
      expect(get('/profile')).to route_to('legacy/users#edit')
    end

    it "routes to #update" do
      expect(put('/profile')).to route_to('legacy/users#update')
    end

    # it "routes to #destroy" do
    #   expect(delete("/user")).to route_to("users#destroy")
    # end

  end
end
