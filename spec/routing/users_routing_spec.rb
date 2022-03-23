require 'rails_helper'

RSpec.describe Legacy::UsersController, :type => :routing do
  describe "routing" do

    it "routes to #update" do
      expect(put('/profile')).to route_to('legacy/users#update')
    end

  end
end
