require 'spec_helper'

describe ContactInfosController do

  describe "GET 'confirm_email'" do
    render_views

    before :each do
      @email = FactoryGirl.create(:email_address, confirmation_code: '1234', verified: false, value: 'user@example.com')
    end

    it "returns error if no code given" do
      get 'confirm_email'
      expect(response.code).to eq('400')
      expect(response.body).to include("Sorry, we couldn't verify an email using the confirmation code you provided.")
      expect(EmailAddress.find_by_value(@email.value).verified).to be_false
    end

    it "returns error if code doesn't match" do
      get 'confirm_email', :code => 'abcd'
      expect(response.code).to eq('400')
      expect(response.body).to include("Sorry, we couldn't verify an email using the confirmation code you provided.")
      expect(EmailAddress.find_by_value(@email.value).verified).to be_false
    end

    it "returns success if code matches" do
      get 'confirm_email', :code => @email.confirmation_code
      expect(response).to be_success
      expect(response.body).to include('Success! Thanks for adding your email address.')
      expect(EmailAddress.find_by_value(@email.value).verified).to be_true
    end
  end
end
