require 'rails_helper'

describe Admin::PreAuthStatesController, type: :controller do
  let(:admin) { FactoryBot.create :user, :admin, :terms_agreed }

  before(:each) do
    mock_current_user(admin)
  end

  context '#index' do
    before do
      FactoryBot.create(:contact_info)

      Timecop.freeze(9.days.ago) do
        FactoryBot.create(:contact_info)
      end
    end

    it 'assigns unverified_contacts' do
      get(:index, params: { since: 2 })
      expect(assigns(:unverified_contacts).count).to eq(1)
    end
  end
end
