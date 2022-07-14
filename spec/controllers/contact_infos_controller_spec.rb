require 'rails_helper'

RSpec.describe ContactInfosController, type: :controller do

  let!(:user)         { FactoryBot.create :user, :terms_agreed }
  let!(:another_user) { FactoryBot.create :user, :terms_agreed }
  let!(:contact_info) { FactoryBot.build :email_address, user: user }

  context 'POST create' do
    it 'creates a new ContactInfo' do
      controller.sign_in! user
      expect { post('create',
          params: {
            contact_info: contact_info.attributes
          }
        )
      }.to(
        change{ContactInfo.count}.by(1)
      )

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

  context "GET confirm/unclaimed" do
    render_views
    let(:user)  { FactoryBot.create :user_with_emails, state: 'unclaimed', emails_count: 1 }

    let(:email) do
      FactoryBot.create(:email_address, user: user,
        confirmation_code: '1234', verified: false, value: 'user@example.com'
      )
    end

    it "returns error if no code given" do
      get(:confirm_unclaimed)
      expect(response.code).to eq('400')
    end
  end

  context '#resend_confirmation' do
    before { contact_info.save! }

    context 'another user' do
      before { controller.sign_in! another_user }

      it 'returns 403 forbidden' do
        put(:resend_confirmation, params: { id: contact_info.id })
        expect(response).to have_http_status :forbidden
      end
    end

    context 'same user' do
      before { controller.sign_in! user }

      it 'returns an `already_confirmed` error when confirmed' do
        ConfirmContactInfo.call(contact_info)
        put(:resend_confirmation, params: { id: contact_info.id })
        expect(response).to have_http_status :success
        expect(response.body).to include(I18n.t :"controllers.contact_infos.already_verified")
      end

      it 'sends the confirmation if all good' do
        expect_any_instance_of(SendContactInfoConfirmation).to(
          receive(:call).with(contact_info: contact_info).and_call_original
        )
        put(:resend_confirmation, params: { id: contact_info.id })
        expect(response).to have_http_status :success
        expect(response.body_as_hash[:message]).to include(
          I18n.t :"controllers.contact_infos.verification_sent", address: contact_info.value
        )
      end
    end
  end
end
