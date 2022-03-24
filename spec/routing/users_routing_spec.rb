require 'rails_helper'

RSpec.describe UsersController, :type => :routing do
  describe "routing" do

    it "routes to #update" do
      expect(put('/profile')).to route_to('users#update')
    end

  end
end
