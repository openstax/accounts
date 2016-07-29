require 'rails_helper'

RSpec.describe Admin::ContactInfosController, type: :controller do
  let!(:user) { FactoryGirl.create :user_with_emails }
  let(:admin) { FactoryGirl.create :user, :admin, :terms_agreed }

  before(:each) do
    controller.sign_in! admin
  end

  it 'marks contact info as verified' do
    email = user.email_addresses.first
    post :verify, id: email.id
    expect(email.reload.verified).to be true
    expect(response.body).to eq '(Verified)'
  end
end
