require 'rails_helper'

RSpec.describe Admin::SalesforceController, type: :controller do
  let(:admin) { FactoryGirl.create :user, :admin, :terms_agreed }

  before(:each) do
    controller.sign_in! admin
  end

  it 'enables emails on manual user updates' do
    expect(UpdateUserSalesforceInfo).to receive(:call).with(allow_error_email: true)
    post :update_users
  end
end
