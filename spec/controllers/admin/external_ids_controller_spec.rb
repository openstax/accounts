require 'rails_helper'

describe Admin::ExternalIdsController, type: :controller do
  let!(:external_id) { FactoryBot.create :external_id }
  let(:admin)        { FactoryBot.create :user, :admin, :terms_agreed }

  before(:each) { controller.sign_in! admin }

  context 'DELETE #destroy' do
    it 'destroys the given external id' do
      expect { delete :destroy, params: { id: external_id.id } }.to change { ExternalId.count }.by(-1)
    end
  end
end
