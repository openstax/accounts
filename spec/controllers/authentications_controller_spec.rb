require 'rails_helper'

describe AuthenticationsController, type: :controller do
  let(:user)            { FactoryGirl.create :user, :terms_agreed }
  let!(:authentication) { FactoryGirl.create :authentication, user: user, provider: 'facebook' }

  context '#destroy' do
    context 'with only 1 authentication' do
      context 'with recent signin' do
        before { controller.sign_in! user }

        it "does not delete the given authentication" do
          expect{ delete 'destroy', provider: authentication.provider }.not_to(
            change{ Authentication.count }
          )
          expect(response).to have_http_status(:unprocessable_entity)
          expect(authentication.reload.destroyed?).to eq false
        end
      end

      context 'with old signin' do
        before { Timecop.freeze(11.minutes.ago) { controller.sign_in! user } }

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
        before { controller.sign_in! user }

        it "deletes the given authentication" do
          expect{ delete 'destroy', provider: authentication.provider }.to(
            change{ Authentication.count }.by(-1)
          )
          expect(response).to have_http_status(:ok)
          expect(user.authentications.count).to eq 1
        end
      end

      context 'with old signin' do
        before { Timecop.freeze(11.minutes.ago) { controller.sign_in! user } }

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
