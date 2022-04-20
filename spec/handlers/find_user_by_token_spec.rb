require 'rails_helper'

describe FindUserByToken, type: :handler do
  context 'when success' do
    before do
      user = create_user('user@openstax.org')
      user.refresh_login_token
      user.save!
      @token = user.login_token
    end

    let(:params) do
      { token: @token }
    end

    let(:result) do
      described_class.call(params: params, caller: AnonymousUser.instance)
    end

    it 'outputs the user found by token' do
      expect(result.outputs.user).to eq(User.first)
    end
  end

  context 'when failure' do
    example 'because no user found' do
      params = { token: '000' }
      result = described_class.call(params: params, caller: AnonymousUser.instance)
      expect(result).to have_routine_error(:unknown_login_token)
    end

    example 'because login token expired' do
      user = create_user('user@openstax.org')
      token = user.refresh_login_token
      user.login_token_expires_at = 1.day.ago
      user.save!
      params = { token: user.login_token }
      result = described_class.call(params: params, caller: AnonymousUser.instance)

      expect(result).to have_routine_error(:expired_login_token)
    end
  end
end
