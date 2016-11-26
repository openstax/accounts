require 'rails_helper'

RSpec.describe IdentitiesController, :type => :routing do
  describe "routing" do

    it "routes to #set" do
      expect(put("/password/set")).to route_to("identities#set")
    end

  end
end
