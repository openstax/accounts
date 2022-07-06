require 'rails_helper'

RSpec.describe OtherController, :type => :routing do
  describe "routing" do

    it "routes to #update" do
      expect(put('/profile')).to route_to('other#update')
    end

  end
end
