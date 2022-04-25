require 'rails_helper'

RSpec.describe PasswordManagementController, type: :controller do
  describe 'GET #forgot_password_form' do
    it 'has a 200 status code' do
      get('forgot_password_form')
      expect(response.status).to eq(200)
    end

    it 'assigns the email value from what is stored in the session' do
      session[:login_failed_email] = 'someone@openstax.org'
      get(:forgot_password_form)
      expect(assigns(:email)).to eq('someone@openstax.org')
    end
  end

  describe 'POST #send_reset_password_email' do
    context 'success' do
        before do
          create_user('user@openstax.org')
          expect_any_instance_of(SendResetPasswordEmail).to receive(:call).once.and_call_original
        end

        let(:params) do
          { forgot_password_form: { email: 'user@openstax.org' } }
        end

        it 'assigns the email value from the handler\'s outputs' do
          post(:send_reset_password_email, params: params)
          expect(assigns(:email)).to eq('user@openstax.org')
        end

        it 'calls sign_out!' do
          expect_any_instance_of(described_class).to receive(:sign_out!).once
          post('send_reset_password_email', params: params)
        end

        it 'renders reset_password_email_sent' do
          post(:send_reset_password_email, params: params)
          expect(response).to render_template(:reset_password_email)
        end

        it 'creates a Security Log' do
          mock_current_user(User.last)
          expect {
            post(:send_reset_password_email, params: params)
          }.to change {
            SecurityLog.where(event_type: :password_reset, user: User.last).count
          }
        end
    end

    context 'failure' do
        let(:params) do
          { forgot_password_form: { email: '' } }
        end

        it 'creates a Security Log' do
          expect {
            post(:send_reset_password_email, params: params)
          }.to change {
            SecurityLog.where(event_type: :reset_password_failed).count
          }
        end

        it 'renders forgot password form' do
          post(:send_reset_password_email, params: params)
          expect(response).to render_template(:forgot_password_form)
        end
    end
  end

  describe 'GET #create_password_form' do
    context 'without a token' do
      it 'renders create_password_form but with status 400' do
        get(:create_password_form)
        expect(response).to render_template(:create_password_form)
        expect(response.status).to eq(400)
      end
    end

    context 'with an invalid token' do
      it 'renders create_password_form but with status 400' do
        get(:create_password_form, params: { token: '123' })
        expect(response).to render_template(:create_password_form)
        expect(response.status).to eq(400)
      end
    end

    context 'with a valid token' do
      before do
        user = create_user('user@openstax.org')
        user.refresh_login_token
        user.save!
        @token = user.login_token
      end

      it 'renders create_password_form with status 200' do
        get(:create_password_form, params: { token: @token })
        expect(response).to render_template(:create_password_form)
        expect(response.status).to eq(200)
      end
    end
  end

  describe 'POST #create_password' do
    it 'creates a password for logged in user'
  end

  describe 'GET #change_password_form' do
    context 'success - when valid token' do
      let(:params) do
        user.refresh_login_token
        user.save

        { token:  user.login_token }
      end

      let(:user) do
        create_user('user@openstax.org')
      end

      it 'logs in the user found by token or whateva' do
        some_other_user = FactoryBot.create(:user)
        get(:change_password_form, params: params)
        expect(controller.current_user.id).to eq(user.id)
        expect(controller.current_user.id).not_to eq(some_other_user.id)
      end

      it 'has a 200 status code' do
        get(:change_password_form, params: params)
        expect(response.status).to eq(200)
      end

      xit 'creates a security log' do
        expect {
          get(:change_password_form, params: params)
        }.to change {
          SecurityLog.where(event_type: :user_password_reset).count
        }
      end
    end

    context 'failure - when invalid token' do
      before do
        user = FactoryBot.create(:user)
      end

      let(:params) do
        { token: SecureRandom.hex(16) } # token is invalid because it doesn't match up with the user's
      end

      it 'responds with 400 error' do
        get(:change_password_form, params: params)
        expect(response.code).to eq('400')
      end

      it 'creates a security log' do
        expect {
          get(:change_password_form, params: params)
        }.to change {
          SecurityLog.where(event_type: :user_password_reset_failed).count
        }
      end
    end
  end

  describe 'POST #change_password' do
    before do
      # bypass re-authentication
      allow_any_instance_of(RequireRecentSignin).to receive(:user_signin_is_too_old?).and_return(false)
      mock_current_user(user)
    end

    let(:user) do
      create_user('user@openstax.org', 'password')
    end

    context 'success' do
      let(:new_password) do
        Faker::Internet.password(min_length: 8)
      end

      let(:params) do
        {
          change_password_form: {
            password: new_password
          }
        }
      end

      it 'sets the new password for the user' do
        expect(User.last.identity.authenticate(new_password)).to be_falsey
        post(:change_password, params: params)
        expect(response.status).to eq(302)
        expect(User.last.identity.authenticate(new_password)).to be_truthy
      end

      it 'creates a security log' do
        expect {
          post(:change_password, params: params)
        }.to change {
          SecurityLog.where(event_type: :password_reset).count
        }
      end
    end

    context 'failure' do
      before do
        # bypass re-authentication
        allow_any_instance_of(RequireRecentSignin).to receive(:user_signin_is_too_old?).and_return(false)
      end

      let(:params) do
        {
          change_password_form: {
            password: ''
          }
        }
      end

      it 'creates a security log' do
        expect {
          post(:change_password, params: params)
        }.to change {
          SecurityLog.where(event_type: :password_reset_failed).count
        }
      end
    end
  end
end
