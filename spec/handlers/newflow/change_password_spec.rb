require 'rails_helper'

module Newflow
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
    let(:params) do
      {
        change_password_form: {
          password: 'pwd',
        }
      }
    end

      it 'fails if password is too short' do
        # create the password to begin with
        FactoryBot.create(:identity, user: user, password: 'password')

        expect(described_class.call(caller: user, params: params).errors.any?).to be(true)
      end
    end
  end
end
