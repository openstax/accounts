require 'rails_helper'

describe AuthenticationsController, type: :controller do
  let(:user)            { FactoryGirl.create :user, :terms_agreed }
  let!(:authentication) { FactoryGirl.create :authentication, user: user, provider: 'facebook' }

  before { controller.sign_in! user }

  context '#destroy' do
    context 'with only 1 authentication' do
      context 'with recent signin' do
        before do
          SecurityLog.create!(user: user, remote_ip: '127.0.0.1',
                              event_type: :sign_in_successful, event_data: {}.to_json)
        end

        it "does not delete the given authentication" do
          expect{ delete 'destroy', provider: authentication.provider }.not_to(
            change{ Authentication.count }
          )
          expect(response).to have_http_status(:unprocessable_entity)
          expect(authentication.reload.destroyed?).to eq false
        end
      end

      context 'with old signin' do
        it "does not delete the given authentication" do
          expect{ delete 'destroy', provider: authentication.provider }.not_to(
            change{ Authentication.count }
          )
          expect(response).to have_http_status(:found)
          expect(authentication.reload.destroyed?).to eq false
        end
      end
    end

    context 'with another authentication' do
      before { FactoryGirl.create :authentication, user: user, provider: 'twitter' }

      context 'with recent signin' do
        before do
          SecurityLog.create!(user: user, remote_ip: '127.0.0.1',
                              event_type: :sign_in_successful, event_data: {}.to_json)
        end

        it "deletes the given authentication" do
          expect{ delete 'destroy', provider: authentication.provider }.to(
            change{ Authentication.count }.by(-1)
          )
          expect(response).to have_http_status(:ok)
          expect(user.authentications.count).to eq 1
        end
      end

      context 'with old signin' do
        it "does not delete the given authentication" do
          expect{ delete 'destroy', provider: authentication.provider }.not_to(
            change{ Authentication.count }
          )
          expect(response).to have_http_status(:found)
          expect(authentication.reload.destroyed?).to eq false
        end
      end
    end
  end
end
