require 'rails_helper'

RSpec.describe EducatorSignupController, type: :controller do

  describe 'POST #sheerid_webhook' do
    let(:handler) { SheerIdWebhook }

    let(:user) { create_user Faker::Internet.email }

    let(:params) do
      { 'verificationId': Faker::Alphanumeric.alphanumeric(number: 24) }
    end

    xit 'is processed by the lev handler' do
      # byebug
      # expect(handler).to receive(:handle)

      post(:sheerid_webhook, params: params)
      expect(response).to have_http_status(:ok)
    end

    describe 'must be externally available' do
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
