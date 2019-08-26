require 'rails_helper'

describe "External relative links", type: :controller do

  controller do
    skip_before_action :authenticate_user!

    before_action {
      request.script_name = "/accounts"
    }

    def index
      redirect_to("/some/path/not/in/accounts")
    end
  end

  it "should not prefix redirects for external relative paths" do
    get(:index)
    expect(URI(response.location).path).not_to start_with("/accounts")
  end
end
