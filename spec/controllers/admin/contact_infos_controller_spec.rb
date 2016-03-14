require 'rails_helper'

RSpec.describe Admin::ContactInfosController, type: :controller do
  let!(:user) { FactoryGirl.create :user_with_emails }

  it 'marks contact info as verified' do
    email = user.email_addresses.first
    post :verify, id: email.id
    expect(email.reload.verified).to be true
    expect(response.body).to eq '(Verified)'
  end
end
