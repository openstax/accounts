require 'rails_helper'

describe IdentitiesController, type: :controller do

  describe 'reset_password' do
    render_views

    let!(:user)     { FactoryGirl.create :user, :terms_agreed, username: 'user_one' }
    let!(:identity) do
      FactoryGirl.create(:identity, user: user, password: 'password').tap do |id|
        GeneratePasswordResetCode.call(id)
      end
    end

    context 'PUT update' do
      before do
        expect(!!identity.authenticate('password')).to eq true
        expect(!!identity.authenticate('new_password')).to eq false

        controller.sign_in! user
      end

      context 'with recent signin' do
        before do
          SecurityLog.create!(user: user, remote_ip: '127.0.0.1',
                              event_type: :sign_in_successful, event_data: {}.to_json)
        end

        it "updates the user's password" do
          put 'update', identity: {
            password: 'new_password', password_confirmation: 'new_password'
          }
          expect(response.status).to eq 202
          expect(!!identity.reload.authenticate('password')).to eq false
          expect(!!identity.authenticate('new_password')).to eq true
        end
      end

      context 'with old signin' do
        it "does not update the user's password" do
          put 'update', identity: {
            password: 'new_password', password_confirmation: 'new_password'
          }
          expect(response.status).to eq 302
          expect(!!identity.reload.authenticate('password')).to eq true
          expect(!!identity.authenticate('new_password')).to eq false
        end
      end
    end

    context 'GET reset_password' do
      it 'returns error if no code given' do
        get 'reset_password'
        expect(response.code).to eq('400')
        expect(response.body).to have_no_missing_translations
        expect(response.body).to include(t :"handlers.identities_reset_password.reset_link_is_invalid")
        expect(response.body).not_to include(t :"identities.reset_password.set_password")
      end

      it "returns error if code doesn't match" do
        get 'reset_password', code: 'abcd'
        expect(response.code).to eq('400')
        expect(response.body).to have_no_missing_translations
        expect(response.body).to include(t :"handlers.identities_reset_password.reset_link_is_invalid")
        expect(response.body).not_to include(t :"identities.reset_password.set_password")
      end

      it 'returns error if code has expired' do
        one_year_later = DateTime.now + 1.year
        allow(DateTime).to receive(:now).and_return(one_year_later)
        get 'reset_password', code: identity.password_reset_code.code
        allow(DateTime).to receive(:now).and_call_original

        expect(response.code).to eq('400')
        expect(response.body).to have_no_missing_translations
        expect(response.body).to include(t :"handlers.identities_reset_password.reset_link_expired")
        expect(response.body).not_to include(t :"identities.reset_password.set_password")
      end

      it 'shows reset password form if code matches' do
        get 'reset_password', code: identity.password_reset_code.code
        expect(response).to be_successful
        expect(response.body).to have_no_missing_translations
        expect(response.body).not_to include(t :"handlers.identities_reset_password.reset_link_is_invalid")
        expect(response.body).to include(t :"identities.reset_password.set_password")
      end
    end

    context 'POST reset_password' do
      it 'returns error if no code given' do
        post 'reset_password'
        expect(response.code).to eq('400')
        expect(response.body).to have_no_missing_translations
        expect(response.body).to include(t :"handlers.identities_reset_password.reset_link_is_invalid")
        expect(response.body).not_to include(t :"identities.reset_password.set_password")
        identity.reload
        expect(identity.authenticate('password')).to be_truthy
      end

      it "returns error if code doesn't match" do
        post 'reset_password', code: 'abcd'
        expect(response.code).to eq('400')
        expect(response.body).to have_no_missing_translations
        expect(response.body).to include(t :"handlers.identities_reset_password.reset_link_is_invalid")
        expect(response.body).not_to include(t :"identities.reset_password.set_password")
        identity.reload
        expect(identity.authenticate('password')).to be_truthy
      end

      it 'returns error if password is empty' do
        post('reset_password', code: identity.password_reset_code.code,
             reset_password: { password: '', password_confirmation: ''})
        expect(response.code).to eq('400')
        expect(response.body).to have_no_missing_translations
        expect(response.body).not_to include(t :"handlers.identities_reset_password.reset_link_is_invalid")
        expect(response.body).to include("Password can't be blank")
        expect(response.body).to include(t :"identities.reset_password.set_password")
        identity.reload
        expect(identity.authenticate('password')).to be_truthy
      end

      it 'returns error if password is too short' do
        post('reset_password', code: identity.password_reset_code.code,
             reset_password: { password: 'pass', password_confirmation: 'pass'})
        expect(response.code).to eq('400')
        expect(response.body).to have_no_missing_translations
        expect(response.body).not_to include(t :"handlers.identities_reset_password.reset_link_is_invalid")
        expect(response.body).to include('Password is too short')
        expect(response.body).to include(t :"identities.reset_password.set_password")
        identity.reload
        expect(identity.authenticate('password')).to be_truthy
      end

      it "returns error if password and password confirmation don't match" do
        post('reset_password', code: identity.password_reset_code.code,
             reset_password: { password: 'password', password_confirmation: 'passwordd'})
        expect(response.code).to eq('400')
        expect(response.body).to have_no_missing_translations
        expect(response.body).not_to include(t :"handlers.identities_reset_password.reset_link_is_invalid")
        expect(response.body).to include("Password doesn't match confirmation")
        expect(response.body).to include(t :"identities.reset_password.set_password")
        identity.reload
        expect(identity.authenticate('password')).to be_truthy
      end

      it 'changes password if everything validates' do
        post('reset_password', code: identity.password_reset_code.code,
             reset_password: { password: 'password!', password_confirmation: 'password!'})
        expect(response).to redirect_to(root_url)
        expect(flash[:alert]).to be_blank
        expect(flash[:notice]).to include(t :"controllers.identities.password_reset_successfully")
        identity.reload
        expect(identity.authenticate('password')).to be_falsey
        expect(identity.authenticate('password!')).to be_truthy
      end

      it 'redirects to password_return_to if it is set in session' do
        session[:password_return_to] = 'http://www.example.com/'
        post('reset_password', code: identity.password_reset_code.code,
             reset_password: { password: 'password!', password_confirmation: 'password!'})

        expect(response.code).to eq('302')
        expect(response.header['Location']).to eq('http://www.example.com/')

        identity.reload
        expect(identity.authenticate('password')).to be_falsey
        expect(identity.authenticate('password!')).to be_truthy
      end
    end

  end

end
