require 'rails_helper'

describe IdentitiesController, type: :controller do

  describe 'reset_password' do
    render_views

    let!(:user)     { FactoryGirl.create :user, :terms_agreed, username: 'user_one' }
    let!(:identity) { FactoryGirl.create(:identity, user: user, password: 'password') }
    let!(:user_no_identity) {
      FactoryGirl.create :user, :terms_agreed, username: 'user_no_identity'
    }

    context "reset_password" do
      # Which, code-wise, is very similar to add_password

      context 'GET logged in' do
        it 'renders reset_password if has a password' do
          controller.sign_in! user
          get 'reset'
          expect(response.body).to include(t :"identities.reset.page_heading")
        end

        it 'redirects to add_password if does not have a password' do
          controller.sign_in! user_no_identity
          expect(get 'reset').to redirect_to password_add_path
        end
      end

      context "GET not logged in" do
        it 'errors if the login token is bad' do
          get :reset, token: '123'
          expect(response.code).to eq('400')
          expect(response.body).to include(t :"identities.there_was_a_problem_with_password_link")
        end

        it 'errors if the login token is expired' do
          user.refresh_login_token(expiration_period: -1.year)
          user.save!
          get :reset, token: user.login_token
          expect(response.code).to eq('400')
          expect(response.body).to include(t :"identities.expired_password_link")
        end
      end

      context "POST not logged in" do
        it 'gives a 403' do
          reset_password('password!', 'password!')
          expect(response.code).to eq('403')
        end
      end

      context "POST logged in" do
        before { controller.sign_in! user }

        it 'returns error if password is empty' do
          reset_password('','')
          expect(response.code).to eq('400')
          expect(response.body).to have_no_missing_translations
          expect(response.body).not_to include(t :"identities.there_was_a_problem_with_password_link")
          expect(response.body).to include("Password can't be blank")
          expect(response.body).to include(t :"identities.reset.submit")
          identity.reload
          expect(identity.authenticate('password')).to be_truthy
        end

        it 'returns error if password is too short' do
          reset_password('pass','pass')
          expect(response.code).to eq('400')
          expect(response.body).to have_no_missing_translations
          expect(response.body).to include('Password is too short')
          expect(response.body).to include(t :"identities.reset.submit")
          identity.reload
          expect(identity.authenticate('password')).to be_truthy
        end

        it "returns error if password and password confirmation don't match" do
          reset_password('password', 'passwordd')
          expect(response.code).to eq('400')
          expect(response.body).to have_no_missing_translations
          expect(response.body).to include("Password confirmation doesn't match Password")
          expect(response.body).to include(t :"identities.reset.submit")
          identity.reload
          expect(identity.authenticate('password')).to be_truthy
        end

        it 'changes password if everything validates' do
          reset_password('password!', 'password!')
          expect(response).to redirect_to(password_reset_success_url)
          expect(flash[:alert]).to be_blank
          identity.reload
          expect(identity.authenticate('password')).to be_falsey
          expect(identity.authenticate('password!')).to be_truthy
        end
      end

      def reset_password(password, confirmation)
        post('reset', set_password: {
          password: password, password_confirmation: confirmation
        })
      end

    end

    context 'send_add' do

      it 'redirects to the home page with a message if the user is not found' do
        post :send_add
        expect(response).to redirect_to root_path
        expect(flash.alert).to eq I18n.t(:'controllers.identities.lost_user')
      end

      xit 'sends a message to add a password to the account if the user is found' do
      end

    end

    context 'send_reset' do

      it 'redirects to the home page with a message if the user is not found' do
        post :send_reset
        expect(response).to redirect_to root_path
        expect(flash.alert).to eq I18n.t(:'controllers.identities.lost_user')
      end

      xit 'sends a reset password message if the user is found' do
      end

    end

  end
end
