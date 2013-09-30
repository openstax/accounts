require 'spec_helper'

describe DoController do

  describe "GET 'confirm_email'" do
    it "returns http success" do
      get 'confirm_email'
      response.should be_success
    end
  end

end
