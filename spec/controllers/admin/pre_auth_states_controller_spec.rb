require 'rails_helper'

RSpec.describe Admin::PreAuthStatesController, type: :controller do
  let(:admin) { FactoryBot.create :user, :admin, :terms_agreed }

  before(:each) do
    mock_current_user(admin)
  end

  context '#index' do
    before do
      FactoryBot.create(:pre_auth_state)
      FactoryBot.create(:contact_info)

      Timecop.freeze(9.days.ago) do
        FactoryBot.create(:pre_auth_state)
        FactoryBot.create(:contact_info)
      end
    end

    it 'sends a message to User to clean up unverified uses' do
      expect(User).to receive(:cleanup_unverified_users).once
      get :index
    end

    it 'assigns pre_auth_states' do
      get(:index, params: { since: 2 })
      expect(assigns(:pre_auth_states).count).to eq(1)
    end

    it 'assigns unverified_contacts' do
      get(:index, params: { since: 2 })
      expect(assigns(:unverified_contacts).count).to eq(1)
    end
  end
end
