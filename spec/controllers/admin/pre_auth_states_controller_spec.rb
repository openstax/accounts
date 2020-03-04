require 'rails_helper'

RSpec.describe Admin::PreAuthStatesController, type: :controller do
  let(:admin) { FactoryBot.create :user, :admin, :terms_agreed }

  before(:each) do
    mock_current_user(admin)
  end

  it 'sends a message to User to clean up unverified uses on index' do
    expect(User).to receive(:cleanup_unverified_users).once
    get :index
  end
end
