require 'rails_helper'

describe SendResetPasswordEmail, type: :handler do
  let(:user) do
    create_user('user@openstax.org', 'password')
  end

  let(:params) do
    {
      forgot_password_form: {
        email: 'user@openstax.org'
      }
    }
  end

  context 'when user is passed-in' do
    it 'sends a password reset email' do
      expect_any_instance_of(SignupPasswordMailer).to receive(:reset_password_email).and_call_original
      described_class.call(params: {}, caller: user)
    end
  end

  context 'when email param is passed-in, no user' do
    it 'updates the password for the user found by email address' do
      user # create it
      expect_any_instance_of(SignupPasswordMailer).to receive(:reset_password_email).and_call_original
      described_class.call(params: params, caller: AnonymousUser.instance)
    end
  end

  it 'creates a login token for user' do
    expect_any_instance_of(User).to receive(:refresh_login_token).and_call_original
    described_class.call(caller: user, params: {})
  end

  it 'resets the login token for user when it has one' do
    expect(user.login_token).to be(nil)
    described_class.call(params: {}, caller: user)
    expect(user.login_token).to be_a(String)
  end

  context 'when no user found' do
    let(:params) do
    {
      forgot_password_form: {
        email: 'noone@openstax.org'
      }
    }
  end

    it 'adds error cannot_find_user' do
      result = described_class.handle(caller: AnonymousUser.instance, params: params)
      expect(result).to have_routine_error(:cannot_find_user)
    end
  end

  context 'when no email present and no logged in user' do
    let(:params) do
      {
        forgot_password_form: {
          email: nil
        }
      }
    end

    subject(:result) do
      described_class.call(params: params, caller: AnonymousUser.instance)
    end

    it 'returns fatal error email is blank' do
      expect(result).to have_routine_error(:email_is_blank)
    end
  end
end
