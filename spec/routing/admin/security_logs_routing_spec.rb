require 'rails_helper'

describe Admin::SecurityLogsController, type: :routing do
  describe "routing" do
    it "routes /admin/security_log to #show" do
      expect(get("/admin/security_log")).to route_to("admin/security_logs#show")
    end
  end
end
