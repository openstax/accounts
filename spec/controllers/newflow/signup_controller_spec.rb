require 'rails_helper'

module Newflow
  RSpec.describe SignupController, type: :controller do
    describe 'GET #welcome' do
      it 'renders welcome form/page' do
        get(:welcome)
        expect(response).to render_template(:welcome)
      end
    end

    describe 'GET #change_signup_email_form' do
      it 'assigns the email instance variable'
    end

    describe 'GET #verify_email_by_code' do
      it ''
    end

    describe 'GET #signup_done' do
      it 'renders' do
        get(:signup_done)
        expect(response).to render_template(:signup_done)
      end
    end
  end
end
