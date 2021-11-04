require 'rails_helper'

RSpec.describe Legacy::SessionsController, type: :controller do
  context '#start' do
    it 'looks for active banners (ones whose expires_at is in the future)' do
      expected = Banner.create!(expires_at: 1.hour.from_now, message: 'aoidfhllakdjf').message
      get(:start)
      expect(assigns(:banners).first.message).to eq expected
    end

    context 'with no banners in the database' do
      it 'success' do
        get(:start)
        expect(response).to have_http_status(:success)
      end
    end
  end

  context '#create' do
    context 'invalid_omniauth_data' do
      it 'sends the user back to the home page with a message' do
        expect(SessionsCreate).to receive(:handle).and_return(
          Hashie::Mash.new(outputs: {}, errors: [code: :invalid_omniauth_data])
        )
        expect(Sentry).not_to receive(:capture_exception)
        expect{ post(:create, params: { provider: 'identity' }) }.not_to(
          change{ ActionMailer::Base.deliveries.count }
        )
        expect(response).to redirect_to root_path
        expect(flash.alert).to eq I18n.t(:'controllers.lost_user')
      end
    end

    context 'unknown_callback_state' do
      it 'sends the user back to the home page with a message' do
        expect(SessionsCreate).to receive(:handle).and_return(
          Hashie::Mash.new(outputs: {}, errors: [code: :unknown_callback_state])
        )
        expect(Sentry).not_to receive(:capture_exception)
        expect{
          post(:create,
            params: { provider: 'identity' }
          )
        }.not_to(
          change{ ActionMailer::Base.deliveries.count }
        )
        expect(response).to redirect_to root_path
        expect(flash.alert).to eq I18n.t(:'controllers.lost_user')
      end
    end

    context 'anything else' do
      it 'raises IllegalState' do
        expect(SessionsCreate).to receive(:handle).and_return(
          Hashie::Mash.new(
            outputs: { status: :something_else },
            errors: [code: :some_error, message: 'Some error']
          )
        )
        expect(Sentry).to receive(:capture_exception) do |exception, *args|
          expect(exception).to be_a(IllegalState)
        end
        expect{ post(:create, params: { provider: 'identity' }) }.not_to(
          change{ ActionMailer::Base.deliveries.count }
        )
        expect(response).to have_http_status(:internal_server_error)
      end
    end
  end
end
