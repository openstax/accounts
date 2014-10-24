require "spec_helper"

RSpec.describe IdentitiesController, :type => :routing do
  describe "routing" do

    it "routes to #new" do
      expect(get("/signup")).to route_to("identities#new")
    end

    it "routes to #update" do
      expect(put("/identity")).to route_to("identities#update")
    end

  end
end
