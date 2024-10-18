require 'rails_helper'

describe ContactInfosController, :type => :routing do
  describe "routing" do

    it "routes to #create" do
      expect(post("/contact_infos")).to route_to("contact_infos#create")
    end

    it "routes to #destroy" do
      expect(delete("/contact_infos/1")).to route_to("contact_infos#destroy", id: "1")
    end

  end
end
