require 'rails_helper'

RSpec.describe ContactInfosController, type: :controller do

  let!(:user)         { FactoryGirl.create :user, :terms_agreed }
  let!(:another_user) { FactoryGirl.create :user, :terms_agreed }
  let!(:contact_info) { FactoryGirl.build :email_address, user: user }

  context 'POST create' do
    it 'creates a new ContactInfo' do
      controller.sign_in! user
      expect { post 'create',
               contact_info: contact_info.attributes }.to(
        change{ContactInfo.count}.by(1))
      expect(response.status).to eq 200
    end
  end

  context 'PUT set_searchable' do
    it 'changes is_searchable' do
      contact_info.save!
      controller.sign_in! user
      expect(contact_info.is_searchable).to eq true

      put 'set_searchable', id: contact_info.id, is_searchable: false
      expect(response.status).to eq 200
      expect(contact_info.reload.is_searchable).to eq false

      put 'set_searchable', id: contact_info.id, is_searchable: true
      expect(response.status).to eq 200
      expect(contact_info.reload.is_searchable).to eq true
    end
  end

  context 'DELETE destroy' do
    it "deletes the given ContactInfo" do
      contact_info.save!
      controller.sign_in! user
      expect { delete 'destroy', id: contact_info.id }.to(
        change{ContactInfo.count}.by(-1))
      expect(response.status).to eq 200
    end
  end

  context "GET 'confirm'" do
    render_views

    before :each do
      @email = FactoryGirl.create(
        :email_address, confirmation_code: '1234', verified: false, value: 'user@example.com'
      )
    end

    it "returns error if no code given" do
      get 'confirm'
      expect(response.code).to eq('400')
      expect(response.body).to have_no_missing_translations
      expect(response.body).to have_content(t :"contact_infos.confirm.verification_code_not_found")
      expect(EmailAddress.find_by_value(@email.value).verified).to be_falsey
    end

    it "returns error if code doesn't match" do
      get 'confirm', code: 'abcd'
      expect(response.code).to eq('400')
      expect(response.body).to have_no_missing_translations
      expect(response.body).to have_content(t :"contact_infos.confirm.verification_code_not_found")
      expect(EmailAddress.find_by_value(@email.value).verified).to be_falsey
    end

    it "returns success if code matches" do
      get 'confirm', code: @email.confirmation_code
      expect(response).to be_success
      expect(response.body).to have_no_missing_translations
      expect(response.body).to have_content(t :"contact_infos.confirm.page_heading.success")
      expect(response.body).to(
        have_content(t :"contact_infos.confirm.you_may_now_close_this_window")
      )
      expect(EmailAddress.find_by_value(@email.value).verified).to be_truthy
    end
  end

  context "GET 'confirm/unclaimed'" do
    render_views
    let(:user)  { FactoryGirl.create :user_with_emails, state: 'unclaimed', emails_count: 1 }

    let(:email) do
      FactoryGirl.create(:email_address, user: user,
                        confirmation_code: '1234', verified: false, value: 'user@example.com' )
    end

    it "returns error if no code given" do
      get 'confirm_unclaimed'
      expect(response.code).to eq('400')
      expect(response.body).to have_no_missing_translations
      expect(response.body).to(
        have_content(t :"contact_infos.confirm_unclaimed.verification_code_not_found")
      )
    end

    it "returns success if code matches" do
      get 'confirm_unclaimed', code: email.confirmation_code
      expect(response).to be_success
      expect(response.body).to have_no_missing_translations
      expect(response.body).to(
        have_content(t :"contact_infos.confirm_unclaimed.thanks_for_validating")
      )
      expect(EmailAddress.find_by_value(email.value).verified).to be_truthy
    end
  end

  context '#resend_confirmation' do
    before { contact_info.save! }

    context 'another user' do
      before { controller.sign_in! another_user }

      it 'returns 403 forbidden' do
        put :resend_confirmation, id: contact_info.id
        expect(response).to have_http_status :forbidden
      end
    end

    context 'same user' do
      before { controller.sign_in! user }

      it 'returns an `already_confirmed` error when confirmed' do
        ConfirmContactInfo.call(contact_info)
        put :resend_confirmation, id: contact_info.id
        expect(response).to have_http_status :success
        expect(response.body).to include(I18n.t :"controllers.contact_infos.already_verified")
      end

      it 'sends the confirmation if all good' do
        expect_any_instance_of(SendContactInfoConfirmation).to(
          receive(:call).with(contact_info: contact_info).and_call_original
        )
        put :resend_confirmation, id: contact_info.id
        expect(response).to have_http_status :success
        expect(response.body_as_hash[:message]).to include(
          I18n.t :"controllers.contact_infos.verification_sent", address: contact_info.value
        )
      end
    end
  end

end
