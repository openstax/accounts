require 'spec_helper'

describe ContactInfosController do

  let!(:user)         { FactoryGirl.create :user, :terms_agreed }
  let!(:contact_info) { FactoryGirl.build :email_address, user: user }

  context 'POST create' do
    it 'creates a new ContactInfo' do
      controller.sign_in user
      expect { post 'create',
               contact_info: contact_info.attributes }.to(
        change{ContactInfo.count}.by(1))
      expect(response.status).to eq 302
    end
  end

  context 'PUT update' do
    it 'toggles is_searchable' do
      contact_info.save!
      controller.sign_in user
      expect(contact_info.is_searchable).to eq true

      put 'update', id: contact_info.id
      expect(response.status).to eq 302
      expect(contact_info.reload.is_searchable).to eq false

      put 'update', id: contact_info.id
      expect(response.status).to eq 302
      expect(contact_info.reload.is_searchable).to eq true
    end
  end

  context 'DELETE destroy' do
    it "deletes the given ContactInfo" do
      contact_info.save!
      controller.sign_in user
      expect { delete 'destroy', id: contact_info.id }.to(
        change{ContactInfo.count}.by(-1))
      expect(response.status).to eq 302
    end
  end

  context "GET 'confirm'" do
    render_views

    before :each do
      @email = FactoryGirl.create(:email_address, confirmation_code: '1234', verified: false, value: 'user@example.com')
    end

    it "returns error if no code given" do
      get 'confirm'
      expect(response.code).to eq('400')
      expect(response.body).to include("Sorry, we couldn't verify an email using the confirmation code you provided.")
      expect(EmailAddress.find_by_value(@email.value).verified).to be_false
    end

    it "returns error if code doesn't match" do
      get 'confirm', :code => 'abcd'
      expect(response.code).to eq('400')
      expect(response.body).to include("Sorry, we couldn't verify an email using the confirmation code you provided.")
      expect(EmailAddress.find_by_value(@email.value).verified).to be_false
    end

    it "returns success if code matches" do
      get 'confirm', :code => @email.confirmation_code
      expect(response).to be_success
      expect(response.body).to include('Success! Thanks for adding your email address.')
      expect(EmailAddress.find_by_value(@email.value).verified).to be_true
    end
  end
end
