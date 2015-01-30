require 'spec_helper'

describe IdentitiesController, type: :controller do

  describe 'reset_password' do
    render_views

    let!(:user) { FactoryGirl.create :user, username: 'user_one' }
    let!(:identity) {
      i = FactoryGirl.create :identity, user: user, password: 'password'
      i.save!
      GeneratePasswordResetCode.call(i)
      i
    }

    context 'PUT update' do
      it "updates the user's password" do
        expect(!!identity.authenticate('password')).to eq true
        expect(!!identity.authenticate('new_password')).to eq false

        controller.sign_in! user
        put 'update', identity: {current_password: 'password',
                                 password: 'new_password',
                                 password_confirmation: 'new_password'}
        expect(response.status).to eq 302
        expect(!!identity.reload.authenticate('password')).to eq true
        expect(!!identity.authenticate('new_password')).to eq false
      end
    end

    context 'GET reset_password' do
      it 'returns error if no code given' do
        get 'reset_password'
        expect(response.code).to eq('400')
        expect(response.body).to include('Reset password link is invalid')
        expect(response.body).not_to include('Set Password')
      end

      it "returns error if code doesn't match" do
        get 'reset_password', code: 'abcd'
        expect(response.code).to eq('400')
        expect(response.body).to include('Reset password link is invalid')
        expect(response.body).not_to include('Set Password')
      end

      it 'returns error if code has expired' do
        one_year_later = DateTime.now + 1.year
        DateTime.stub(:now).and_return(one_year_later)
        get 'reset_password', code: identity.password_reset_code.code
        DateTime.unstub(:now)

        expect(response.code).to eq('400')
        expect(response.body).to include('Reset password link has expired')
        expect(response.body).not_to include('Set Password')
      end

      it 'shows reset password form if code matches' do
        get 'reset_password', code: identity.password_reset_code.code
        expect(response).to be_successful
        expect(response.body).not_to include('Reset password link is invalid')
        expect(response.body).to include('Set Password')
      end
    end

    context 'POST reset_password' do
      it 'returns error if no code given' do
        post 'reset_password'
        expect(response.code).to eq('400')
        expect(response.body).to include('Reset password link is invalid')
        expect(response.body).not_to include('Set Password')
        identity.reload
        expect(identity.authenticate('password')).to be_true
      end

      it "returns error if code doesn't match" do
        post 'reset_password', code: 'abcd'
        expect(response.code).to eq('400')
        expect(response.body).to include('Reset password link is invalid')
        expect(response.body).not_to include('Set Password')
        identity.reload
        expect(identity.authenticate('password')).to be_true
      end

      it 'returns error if password is empty' do
        post('reset_password', code: identity.password_reset_code.code,
             reset_password: { password: '', password_confirmation: ''})
        expect(response.code).to eq('400')
        expect(response.body).not_to include('Reset password link is invalid')
        expect(response.body).to include("Password can't be blank")
        expect(response.body).to include('Set Password')
        identity.reload
        expect(identity.authenticate('password')).to be_true
      end

      it 'returns error if password is too short' do
        post('reset_password', code: identity.password_reset_code.code,
             reset_password: { password: 'pass', password_confirmation: 'pass'})
        expect(response.code).to eq('400')
        expect(response.body).not_to include('Reset password link is invalid')
        expect(response.body).to include('Password is too short')
        expect(response.body).to include('Set Password')
        identity.reload
        expect(identity.authenticate('password')).to be_true
      end

      it "returns error if password and password confirmation don't match" do
        post('reset_password', code: identity.password_reset_code.code,
             reset_password: { password: 'password', password_confirmation: 'passwordd'})
        expect(response.code).to eq('400')
        expect(response.body).not_to include('Reset password link is invalid')
        expect(response.body).to include("Password doesn&#x27;t match confirmation")
        expect(response.body).to include('Set Password')
        identity.reload
        expect(identity.authenticate('password')).to be_true
      end

      it 'changes password if everything validates' do
        post('reset_password', code: identity.password_reset_code.code,
             reset_password: { password: 'password!', password_confirmation: 'password!'})
        url = controller.send(:without_interceptor) { root_url }
        expect(response).to redirect_to(url)
        expect(flash[:alert]).to be_blank
        expect(flash[:notice]).to include('Your password has been reset successfully! You have been signed in automatically.')
        identity.reload
        expect(identity.authenticate('password')).to be_false
        expect(identity.authenticate('password!')).to be_true
      end

      it 'redirects to return_to if it is encrypted and signed in url' do
        post('reset_password', code: identity.password_reset_code.code,
             reset_password: { password: 'password!', password_confirmation: 'password!'},
             return_to: ActionInterceptor::Encryptor.encrypt_and_sign(
                          'http://www.example.com/'))

        expect(response.code).to eq('302')
        expect(response.header['Location']).to eq('http://www.example.com/')

        identity.reload
        expect(identity.authenticate('password')).to be_false
        expect(identity.authenticate('password!')).to be_true
      end

      it 'redirects to return_to if it is set in session' do
        session[:interceptor] = {return_to: 'http://www.example.com/'}
        post('reset_password', code: identity.password_reset_code.code,
             reset_password: { password: 'password!', password_confirmation: 'password!'})

        expect(response.code).to eq('302')
        expect(response.header['Location']).to eq('http://www.example.com/')

        identity.reload
        expect(identity.authenticate('password')).to be_false
        expect(identity.authenticate('password!')).to be_true
      end
    end
  end

end
