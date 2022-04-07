require 'rails_helper'

describe ChangePassword, type: :handler do
  let(:user) do
    FactoryBot.create(:user)
  end

  context 'success' do
    before do
      FactoryBot.create(:identity, user: user, password: 'password')
    end

    let(:params) do
      {
        change_password_form: {
          password: 'newpassword'
        }
      }
    end

    it "changes the user's identity's password" do
      described_class.call(caller: user, params: params)
      user.identity.reload
      expect(user.identity.password).to eq('newpassword')
    end
  end

  context 'failure' do
    before do
      FactoryBot.create(:identity, user: user, password: 'password')
    end

    let(:params) do
      {
        change_password_form: {
          password: password,
        }
      }
    end

    describe 'fails if password is too short' do
      let(:password) { 'pwd' }

      example do
        result = described_class.call(caller: user, params: params)

        expect(result.errors.any?).to be(true)
        expect(result).to have_routine_error(:too_short)
      end
    end

    describe 'fails if password is the same as before' do
      let(:password) { 'password' }

      example do
        result = described_class.call(caller: user, params: params)
        expect(result.errors.any?).to be(true)
        expect(result).to have_routine_error(:same_password)
      end
    end
  end
end
