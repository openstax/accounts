require 'rails_helper'

RSpec.describe IdentitiesController, :type => :routing do
  describe "routing" do

    it "routes to #update" do
      expect(put("/identity")).to route_to("identities#update")
    end

  end
end
