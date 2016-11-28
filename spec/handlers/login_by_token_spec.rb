require 'rails_helper'

describe LogInByToken, type: :handler do
  let!(:user) { FactoryGirl.create :user }

  let(:user_state) do
    class SpecUserState; def sign_in!(*args); end; end
    SpecUserState.new
  end

  context "user logged in" do
    let(:caller) { user }

    it 'returns quickly' do
      expect(handle.errors).to be_empty
    end
  end

  context "user not logged in" do
    let(:caller) { AnonymousUser.instance }

    context "errors happen" do
      let(:user_state) { 42 } # will freak out if sign_in! called

      it 'if login_token nil' do
        @params = {token: nil}
        expect(handle).to have_routine_error(:token_blank)
      end

      it 'if login_token blank' do
        @params = {token: ''}
        expect(handle).to have_routine_error(:token_blank)
      end

      it 'if login_token does not map to user' do
        @params = {token: '1234'}
        expect(handle).to have_routine_error(:unknown_login_token)
      end

      it 'if login_token is expired' do
        user.reset_login_token(expiration_period: -1.year)
        user.save!
        @params = {token: user.login_token}
        expect(handle).to have_routine_error(:expired_login_token)
      end
    end

    it 'logs in the user on success' do
      user.reset_login_token
      user.save!
      @params = {token: user.login_token}
      expect(user_state).to receive(:sign_in!).with(user, {security_log_data: {type: 'token'}})
      expect(handle.errors).to be_empty
    end
  end

  def handle
    described_class.handle({user_state: user_state, caller: caller, params: @params})
  end

end
