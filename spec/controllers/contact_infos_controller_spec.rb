require 'rails_helper'

describe ContactInfosController, type: :controller do

  let!(:user)         { FactoryGirl.create :user, :terms_agreed }
  let!(:contact_info) { FactoryGirl.build :email_address, user: user }

  context 'POST create' do
    it 'creates a new ContactInfo' do
      controller.sign_in! user
      expect { post 'create',
               contact_info: contact_info.attributes }.to(
        change{ContactInfo.count}.by(1))
      expect(response.status).to eq 200
    end
  end

  context 'PUT set_searchable' do
    it 'changes is_searchable' do
      contact_info.save!
      controller.sign_in! user
      expect(contact_info.is_searchable).to eq true

      put 'set_searchable', id: contact_info.id, is_searchable: false
      expect(response.status).to eq 200
      expect(contact_info.reload.is_searchable).to eq false

      put 'set_searchable', id: contact_info.id, is_searchable: true
      expect(response.status).to eq 200
      expect(contact_info.reload.is_searchable).to eq true
    end
  end

  context 'DELETE destroy' do
    it "deletes the given ContactInfo" do
      contact_info.save!
      controller.sign_in! user
      expect { delete 'destroy', id: contact_info.id }.to(
        change{ContactInfo.count}.by(-1))
      expect(response.status).to eq 200
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
      expect(response.body).to include("Sorry, we couldn't verify an email using the verification code you provided.")
      expect(EmailAddress.find_by_value(@email.value).verified).to be_falsey
    end

    it "returns error if code doesn't match" do
      get 'confirm', :code => 'abcd'
      expect(response.code).to eq('400')
      expect(response.body).to include("Unable to verify email address") # header
      expect(response.body).to include("Sorry, we couldn't verify an email using the verification code you provided.") # body
      expect(EmailAddress.find_by_value(@email.value).verified).to be_falsey
    end

    it "returns success if code matches" do
      get 'confirm', :code => @email.confirmation_code
      expect(response).to be_success
      expect(response.body).to include("Thank you for verifying your email address.") # header
      expect(response.body).to include('Success! Thanks for adding your email address.') # body
      expect(EmailAddress.find_by_value(@email.value).verified).to be_truthy
    end
  end

  context "GET 'confirm/unclaimed'" do
    render_views
    let(:user){ FactoryGirl.create :user_with_emails, state: 'unclaimed', emails_count: 1 }

    let(:email){
      FactoryGirl.create(:email_address, user: user,
                        confirmation_code: '1234', verified: false, value: 'user@example.com' )
    }

    it "returns error if no code given" do
      get 'confirm_unclaimed'
      expect(response.code).to eq('400')
      expect(response.body).to include("we couldn't find any pending invitations")
    end

    it "returns success if code matches" do
      get 'confirm_unclaimed', :code => email.confirmation_code
      expect(response).to be_success
      expect(response.body).to include('Thanks for validating your OpenStax invitation')
      expect(EmailAddress.find_by_value(email.value).verified).to be_truthy
    end

  end

end
