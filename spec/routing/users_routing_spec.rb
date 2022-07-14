require 'rails_helper'

RSpec.describe ProfileController, :type => :routing do
  describe "routing" do

    it "routes to #update" do
      expect(put('/profile')).to route_to('profile#update')
    end

  end
end
