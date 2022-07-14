require 'rails_helper'

RSpec.describe ContactInfosController, type: :controller do
  let!(:user)         { FactoryBot.create :user, :terms_agreed }
  let!(:another_user) { FactoryBot.create :user, :terms_agreed }
  let!(:contact_info) { FactoryBot.build :email_address, user: user }

  context 'POST create' do
    it 'creates a new ContactInfo' do
      controller.sign_in! user
      expect { post('create', params: { contact_info: contact_info.attributes }) }
      expect(response.status).to eq 200
    end
  end

  context 'PUT set_searchable' do
    it 'changes is_searchable' do
      contact_info.save!
      controller.sign_in! user
      expect(contact_info.is_searchable).to eq true

      put(:set_searchable, params: { id: contact_info.id, is_searchable: false })
      expect(response.status).to eq 200
      expect(contact_info.reload.is_searchable).to eq false

      put(:set_searchable, params: { id: contact_info.id, is_searchable: true })
      expect(response.status).to eq 200
      expect(contact_info.reload.is_searchable).to eq true
    end
  end

  context 'DELETE destroy' do
    it "deletes the given ContactInfo" do
      contact_info.save!
      controller.sign_in! user
      expect { delete(:destroy, params: { id: contact_info.id }) }.to(
        change{ContactInfo.count}.by(-1))
      expect(response.status).to eq 200
    end
  end
end
