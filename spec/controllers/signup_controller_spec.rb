require 'rails_helper'

RSpec.describe SignupController, type: :controller do
  describe 'GET #welcome' do
    it 'renders welcome form/page' do
      get(:welcome)
      expect(response).to render_template(:welcome)
    end
  end

  describe 'GET #signup_done' do
    before do
      user = FactoryBot.create(:user)
      mock_current_user(user)
    end

    xit 'renders' do
      get(:signup_done)
      expect(response).to render_template(:signup_done)
    end
  end
end
