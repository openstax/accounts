require 'rails_helper'

RSpec.describe ExternalUserCredentialsController, type: :controller do
  render_views

  let(:user)             { FactoryBot.create :user, :terms_agreed, state: User::EXTERNAL }
  let(:token)            { FactoryBot.create :doorkeeper_access_token, resource_owner_id: user.id }
  let(:return_to)        { 'http://localhost' }
  let(:valid_get_params) { { token: token.token, return_to: return_to } }

  context 'GET new' do
    context 'external user' do
      context 'trusted return_to param' do
        context 'with token' do
          it 'renders the external user credentials creation form' do
            get :new, params: valid_get_params
            expect(response.status).to eq 200
          end
        end

        context 'no token' do
          it 'raises SecurityTransgression' do
            get :new, params: valid_get_params.merge(token: nil)
            expect(response.status).to eq 403
          end
        end
      end

      context 'untrusted return_to param' do
        it 'raises SecurityTransgression' do
          get :new, params: valid_get_params.merge(return_to: 'https://www.example.com')
          expect(response.status).to eq 403
        end
      end
    end

    context 'not an external user' do
      before { user.update_attribute :state, User::ACTIVATED }

      it 'raises SecurityTransgression' do
        get :new, params: valid_get_params
        expect(response.status).to eq 403
      end
    end
  end

  context 'POST create' do
    let(:valid_params) do
      valid_get_params.merge(signup: {
        first_name: 'Test',
        last_name: 'User',
        email: 'test@example.com',
        password: 'abcd1234'
      })
    end

    context 'external user' do
      context 'trusted return_to param' do
        context 'with token' do
          context 'valid signup params' do
            it 'creates a new EmailAddress for the external user and redirects back' do
              expect do
                post :create, params: valid_params
              end.to change { EmailAddress.count }.by(1)

              expect(response).to redirect_to return_to
            end
          end

          context 'invalid signup params' do
            context 'no signup params' do
              it 're-renders the form with error messages' do
                expect do
                  post :create, params: valid_params.merge(signup: {})
                end.not_to change { EmailAddress.count }

                expect(response.status).to eq 200
                expect(response.body).to include "First name can't be blank"
                expect(response.body).to include "Last name can't be blank"
                expect(response.body).to include "Email can't be blank"
                expect(response.body).to include "Password can't be blank"
              end
            end

            context 'password too short' do
              it 're-renders the form with error messages' do
                expect do
                  post :create, params: valid_params.merge(
                    signup: valid_params[:signup].merge(password: 'abc123')
                    )
                end.not_to change { EmailAddress.count }

                expect(response.status).to eq 200
                expect(response.body).to include 'Password is too short (minimum is 8 characters)'
              end
            end
          end
        end

        context 'no token' do
          it 'raises SecurityTransgression' do
            post :create, params: valid_params.merge(token: nil)
            expect(response.status).to eq 403
          end
        end
      end

      context 'untrusted return_to param' do
        it 'raises SecurityTransgression' do
          get :new, params: valid_params.merge(return_to: 'https://www.example.com')
          expect(response.status).to eq 403
        end
      end
    end

    context 'not an external user' do
      before { user.update_attribute :state, User::ACTIVATED }

      it 'raises SecurityTransgression' do
        post :create, params: valid_params
        expect(response.status).to eq 403
      end
    end
  end
end
