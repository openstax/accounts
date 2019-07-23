require 'rails_helper'

RSpec.describe Admin::ContactInfosController, type: :controller do
  let!(:user) { FactoryBot.create :user_with_emails }
  let(:admin) { FactoryBot.create :user, :admin, :terms_agreed }
  let(:email) { user.email_addresses.first }

  before(:each) do
    controller.sign_in! admin
  end

  it 'marks contact info as verified' do
    post :verify, params: { id: email.id }
    expect(email.reload.verified).to be true
    expect(response.body).to eq '(Confirmed)'
  end

  describe '#delete contact_info' do
    it 'removes a contact info' do
      MarkContactInfoVerified.call(email)
      delete :destroy, params: { id: email.id }
      expect{ email.reload }.to raise_error ActiveRecord::RecordNotFound
    end
  end


end
