require 'rails_helper'

module Newflow
  describe ResetPassword, type: :handler do
    let(:user) do
      create_newflow_user('user@openstax.org', 'password')
    end

    let(:params) do
      {
        reset_password_form: {
          email: 'user@openstax.org'
        }
      }
    end

    context 'when user is passed-in' do
      it 'sends a password reset email' do
        expect_any_instance_of(NewflowMailer).to receive(:reset_password_email).and_call_original
        described_class.call(params: {}, user: user)
      end
    end

    context 'when email param is passed-in, no user' do
      it 'updates the password for the user found by email address' do
        user # create it
        expect_any_instance_of(NewflowMailer).to receive(:reset_password_email).and_call_original
        described_class.call(params: params, user: nil)
      end
    end

    it 'creates a login token for user' do
      expect_any_instance_of(User).to receive(:refresh_login_token).and_call_original
      described_class.call(user: user, params: {})
    end

    it 'resets the login token for user when it has one' do
      expect(user.login_token).to be(nil)
      described_class.call(params: {}, user: user)
      expect(user.login_token).to be_a(String)
    end

    context 'when no user found' do
      let(:params) do
      {
        reset_password_form: {
          email: 'noone@openstax.org'
        }
      }
    end

      it 'adds error cannot_find_user' do
        result = described_class.handle(user: nil, params: params)
        expect(result).to have_routine_error(:cannot_find_user)
      end
    end
  end
end
