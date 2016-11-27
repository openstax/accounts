require 'rails_helper'

describe IdentitiesController, type: :controller do

  describe 'reset_password' do
    render_views

    let!(:user)     { FactoryGirl.create :user, :terms_agreed, username: 'user_one' }
    let!(:identity) { FactoryGirl.create(:identity, user: user, password: 'password') }
    let!(:user_no_identity) {
      FactoryGirl.create :user, :terms_agreed, username: 'user_no_identity'
    }

    context 'PUT set' do
      before do
        expect(!!identity.authenticate('password')).to eq true
        expect(!!identity.authenticate('new_password')).to eq false
      end

      context "anonymous user" do
        it "requires login" do
          expect(
            put 'set', set_password: {
              password: 'new_password', password_confirmation: 'password_confirmation'
            }
          ).to redirect_to login_path
        end
      end

      context "logged in user" do
        context 'with recent signin' do
          before { controller.sign_in! user }

          it "updates the user's password" do
            put 'set', set_password: {
              password: 'new_password', password_confirmation: 'new_password'
            }
            expect(response.status).to eq 202
            expect(!!identity.reload.authenticate('password')).to eq false
            expect(!!identity.authenticate('new_password')).to eq true
          end
        end

        context 'with old signin' do
          before { Timecop.freeze(11.minutes.ago) { controller.sign_in! user } }

          it "does not update the user's password" do
            put 'set', set_password: {
              password: 'new_password', password_confirmation: 'new_password'
            }
            expect(response.status).to eq 302
            expect(!!identity.reload.authenticate('password')).to eq true
            expect(!!identity.authenticate('new_password')).to eq false
          end
        end
      end
    end

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
          expect(response.body).to include(t :"identities.there_was_a_problem_with_reset_link")
        end

        it 'errors if the login token is expired' do
          user.reset_login_token(expiration_period: -1.year)
          user.save!
          get :reset, token: user.login_token
          expect(response.code).to eq('400')
          expect(response.body).to include(t :"identities.expired_reset_link")
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
          expect(response.body).not_to include(t :"identities.there_was_a_problem_with_reset_link")
          expect(response.body).to include("Password can't be blank")
          expect(response.body).to include(t :"identities.set_password")
          identity.reload
          expect(identity.authenticate('password')).to be_truthy
        end

        it 'returns error if password is too short' do
          reset_password('pass','pass')
          expect(response.code).to eq('400')
          expect(response.body).to have_no_missing_translations
          expect(response.body).to include('Password is too short')
          expect(response.body).to include(t :"identities.set_password")
          identity.reload
          expect(identity.authenticate('password')).to be_truthy
        end

        it "returns error if password and password confirmation don't match" do
          reset_password('password', 'passwordd')
          expect(response.code).to eq('400')
          expect(response.body).to have_no_missing_translations
          expect(response.body).to include("Password confirmation doesn't match Password")
          expect(response.body).to include(t :"identities.set_password")
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

  end
end
