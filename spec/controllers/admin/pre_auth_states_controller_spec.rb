require 'rails_helper'

describe Admin::PreAuthStatesController, type: :controller do
  render_views

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

    it 'renders the confirmation url for each unverified contact' do
      get(:index, params: { since: 2 })
      expect(response).to have_http_status(:ok)
      contact = assigns(:unverified_contacts).first
      expect(response.body).to include(contact.confirmation_code)
    end
  end
end
