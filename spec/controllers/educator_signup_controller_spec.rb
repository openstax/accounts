require 'rails_helper'

RSpec.describe EducatorSignupController, type: :controller do

  describe 'GET #sheerid_form' do
    it 'requires a logged in user'
  end

  describe 'POST #sheerid_webhook' do
    let(:handler) { SheeridWebhook }

    let(:params) do
      { 'verificationId': Faker::Alphanumeric.alphanumeric(number: 24) }
    end

    it 'is processed by the lev handler' do
      expect(handler).to receive(:handle)

      post(:sheerid_webhook, params: params)
    end

    context 'must be externally available' do
      before(:each) do
        allow(handler).to receive(:handle).and_return(true)
      end

      it 'is not forgery protected' do
        with_forgery_protection do
          expect_any_instance_of(ActionController::Base).not_to receive(:verify_authenticity_token)

          post(:sheerid_webhook, params: params)
        end
      end
    end
  end
end