require 'rails_helper'

describe Legacy::UsersController, type: :controller do

  let!(:user) { FactoryBot.create :user, :terms_agreed }

  before { controller.sign_in! user }

  context 'PUT update' do
    it 'saves a single field and returns the new full name' do
      put(:update, params: { name: 'first_name', value: 'Ada' })

      expect(response.status).to eq 200
      expect(response.media_type).to eq 'application/json'
      expect(JSON.parse(response.body)['full_name']).to include 'Ada'
      expect(user.reload.first_name).to eq 'Ada'
    end

    it 'saves the whole name at once' do
      put(:update, params: { value: { title: 'Dr', first_name: 'Ada', last_name: 'Lovelace' } })

      expect(response.status).to eq 200
      expect(user.reload.last_name).to eq 'Lovelace'
    end

    # The profile page's inline editors render whatever comes back on a failure,
    # so every response has to be JSON -- an HTML error page ends up displayed as
    # markup under the inputs.
    it 'answers JSON even when the request negotiates HTML' do
      put(:update, params: { name: 'first_name', value: 'Ada' }, format: :html)

      expect(response.status).to eq 200
      expect(response.media_type).to eq 'application/json'
      expect(response.body).not_to include '<!DOCTYPE'
    end

    it 'returns validation failures as a JSON list of messages' do
      put(:update, params: { name: 'username', value: 'no spaces allowed' })

      expect(response.status).to eq 422
      expect(response.media_type).to eq 'application/json'

      errors = JSON.parse(response.body)['errors']
      expect(errors).to be_an Array
      expect(errors.first).to be_present
    end

    # The attribute name is client-supplied and the resulting hash skips strong
    # parameters, so anything outside the profile page's own fields is refused.
    it 'refuses to write a field the profile page does not edit' do
      expect { put(:update, params: { name: 'is_administrator', value: 'true' }) }
        .not_to change { user.reload.is_administrator }

      expect(response.status).to eq 403
    end

    it 'refuses to write a field the profile page does not edit via the hash form' do
      put(:update, params: { value: { first_name: 'Ada', is_administrator: 'true' } })

      expect(response.status).to eq 200
      expect(user.reload.is_administrator).to eq false
      expect(user.first_name).to eq 'Ada'
    end
  end
end
