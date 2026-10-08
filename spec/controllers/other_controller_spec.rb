require 'rails_helper'

describe OtherController, type: :controller do
  describe 'GET #profile_newflow' do
    context 'when logged in' do
      before do
        user.update!(role: User::INSTRUCTOR_ROLE)
        mock_current_user(user)
      end

      let(:user) { create_newflow_user('user@openstax.org') }

      context 'when profile is complete' do
        before do
          user.update!(is_profile_complete: true)
        end

          it 'renders 200 OK status' do
          get(:profile_newflow)
          expect(response.status).to eq(200)
        end

        it 'renders profile_newflow' do
          get(:profile_newflow)
          expect(response).to render_template(:profile_newflow)
        end
      end

      context 'when have not completed verification' do
        before { user.update!(is_profile_complete: false) }

        it 'redirects to step 3 — complete SheerID' do
          get(:profile_newflow)
          expect(response).to redirect_to(educator_sheerid_form_path)
        end
      end

      context 'when profile is not complete and not SheerID eligible/skipped' do
        before { user.update!(is_profile_complete: false, is_sheerid_unviable: true) }

        it 'redirects to step 4 — complete profile form' do
          get(:profile_newflow)
          expect(response).to redirect_to(educator_profile_form_path)
        end
      end
    end

    context 'while not logged in' do
      it 'redirects to login form' do
        get(:profile_newflow)
        expect(response).to redirect_to newflow_login_path
      end
    end
  end

  describe "GET #exit_accounts" do
    let(:host) { Rails.application.secrets.trusted_hosts.first }
    let(:target_url) { Faker::Internet.url }

    context 'when Referer is present' do
      before do
        request.headers.merge!({ Referer: subject })
      end

      context 'when Referer includes `r` param' do
        subject do
          "#{host}?r=#{target_url}"
        end

        context 'when `r` is trusted' do
          before do
            allow(Host).to receive(:trusted?).with(target_url).once.and_return(true)
          end

          it 'redirects to `r`' do
            get(:exit_accounts)
            expect(response).to redirect_to(target_url)
          end
        end

        context 'when `r` is not trusted' do
          before do
            allow(Host).to receive(:trusted?).with(target_url).once.and_return(false)
          end

          it 'is forbidden' do
            get(:exit_accounts)
            expect(response).to have_http_status(:forbidden)
          end
        end
      end
    end

    context 'when Referer is nil' do
      it 'redirects back' do
        expect_any_instance_of(described_class).to receive(:redirect_back).and_call_original
        get(:exit_accounts)
        expect(response).to redirect_to(root_url)
      end
    end

    context 'when the stored url includes `redirect_uri` param' do
      before do
        allow_any_instance_of(described_class).to receive(:stored_url).and_return(redirect_uri)
      end

      let(:redirect_uri) do
        "#{host}?redirect_uri=#{target_url}"
      end

      it 'redirects to `redirect_uri`' do
        get(:exit_accounts)
        expect(response).to redirect_to(target_url)
      end
    end
  end

  describe 'GET #data_export' do
    let(:user) { create_newflow_user('user@openstax.org', 'password') }

    it 'redirects to login when not signed in' do
      get :data_export
      expect(response).to redirect_to(newflow_login_path)
    end

    it 'returns a JSON attachment for the current user' do
      mock_current_user(user)
      get :data_export

      expect(response).to be_successful
      expect(response.headers['Content-Type']).to include('application/json')
      expect(response.headers['Content-Disposition']).to include('attachment')
      payload = JSON.parse(response.body)
      expect(payload['profile']['uuid']).to eq(user.uuid)
    end

    it 'logs a security event' do
      mock_current_user(user)
      expect {
        get :data_export
      }.to change { SecurityLog.where(event_type: :user_data_exported).count }.by(1)
    end
  end

  describe 'POST #request_account_deletion' do
    let(:user) { create_newflow_user('user@openstax.org', 'password') }

    it 'redirects to login when not signed in' do
      post :request_account_deletion
      expect(response).to redirect_to(newflow_login_path)
    end

    it 'sets a deletion token and redirects with a notice' do
      mock_current_user(user)
      post :request_account_deletion

      expect(user.reload.account_deletion_token).to be_present
      expect(response).to redirect_to(profile_newflow_path)
      expect(flash[:notice]).to be_present
    end
  end

  describe 'GET #confirm_account_deletion_form' do
    let(:user) { create_newflow_user('user@openstax.org', 'password') }

    it 'redirects with an alert when the token is unknown' do
      get :confirm_account_deletion_form, params: { token: 'nope' }
      expect(response).to be_redirect
      expect(flash[:alert]).to be_present
    end

    it 'renders the confirm form when the token is valid' do
      user.refresh_account_deletion_token(expiration_period: 1.day)
      user.save!

      get :confirm_account_deletion_form, params: { token: user.account_deletion_token }
      expect(response).to be_successful
    end
  end

  describe 'POST #confirm_account_deletion' do
    let(:user) { create_newflow_user('user@openstax.org', 'password') }

    before do
      user.refresh_account_deletion_token(expiration_period: 1.day)
      user.save!
    end

    it 'soft-deletes the user and redirects to login' do
      post :confirm_account_deletion, params: { token: user.account_deletion_token }
      expect(user.reload.is_deleted).to eq(true)
      expect(response).to redirect_to(newflow_login_path)
    end

    it 'logs an account_deleted security event' do
      expect {
        post :confirm_account_deletion, params: { token: user.account_deletion_token }
      }.to change { SecurityLog.where(event_type: :account_deleted).count }.by(1)
    end

    it 'redirects with an alert when the token is invalid' do
      post :confirm_account_deletion, params: { token: 'bogus' }
      expect(user.reload.is_deleted).not_to eq(true)
      expect(flash[:alert]).to be_present
    end
  end
end
