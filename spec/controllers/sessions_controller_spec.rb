require 'rails_helper'

RSpec.describe SessionsController, type: :controller do

  context '#create' do
    context 'invalid_omniauth_data' do
      it 'sends the user back to the home page with a message' do
        post :create, provider: 'identity'
        expect(response).to redirect_to root_path
        expect(flash.alert).to eq 'Sorry, we lost you. Please log in again.'
      end
    end

    context 'unknown_callback_state' do
      it 'sends the user back to the home page with a message' do
        new_env = request.env.merge('omniauth.auth' => { provider: 'identity' })
        allow(request).to receive(:env).and_return(new_env)
        post :create, provider: 'identity'
        expect(response).to redirect_to root_path
        expect(flash.alert).to eq 'Sorry, we lost you. Please log in again.'
      end
    end
  end

end
