require 'rails_helper'

describe RecodeUrl do

    let(:app) { RecodeUrl.new(Rails.application) }
    subject { described_class.new(app) }

    let(:request) { Rack::MockRequest.new(subject) }
  
    context "when called with a GET request" do
        before(:each) do
            request.get("/accounts/api/user", 'CONTENT_TYPE' => 'text/plain')
        end
        it "changes PATH_INFO" do
            expect(app["PATH_INFO"]).to eq('text/plain')
        end
    end
end