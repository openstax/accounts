require 'rails_helper'

describe 'Self-service account deletion', type: :request do
  let!(:user) { FactoryBot.create :user_with_emails, :terms_agreed, is_newflow: true, role: :student }

  def sign_in_with_sso_cookie(user)
    secrets = Rails.application.secrets.sso[:cookie]
    cookies[secrets[:name]] = SsoCookie.generate(value: { sub: SsoCookie.user_hash(user) })
  end

  before do
    user.email_addresses.first.update!(verified: true)
    user.refresh_account_deletion_token(expiration_period: 1.day)
    user.save!
  end

  it 'does not delete the account on GET, so email prefetchers are harmless' do
    get confirm_account_deletion_form_path(token: user.account_deletion_token)

    expect(response).to have_http_status(:ok)
    expect(user.reload.is_deleted).to be_falsey
    expect(user.account_deletion_token).to be_present
  end

  it 'deletes the account on POST and burns the token' do
    token = user.account_deletion_token
    post confirm_account_deletion_path, params: { token: token }

    expect(user.reload.is_deleted).to eq(true)

    post confirm_account_deletion_path, params: { token: token }
    expect(response).to redirect_to(newflow_login_path)
    expect(flash[:alert]).to be_present
  end

  it 'turns an SSO cookie that predates the deletion into an anonymous session' do
    sign_in_with_sso_cookie(user)
    get profile_newflow_path
    expect(response).to have_http_status(:ok)

    SoftDeleteUser.call(user)

    get profile_newflow_path
    expect(response).to redirect_to(newflow_login_path)
  end

  it 'revokes the user\'s OAuth access tokens and grants' do
    token = FactoryBot.create(:doorkeeper_access_token, resource_owner_id: user.id)
    other = FactoryBot.create(:doorkeeper_access_token, resource_owner_id: FactoryBot.create(:user).id)

    SoftDeleteUser.call(user)

    expect(token.reload).to be_revoked
    expect(other.reload).not_to be_revoked
  end
end
