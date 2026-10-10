require 'rails_helper'

describe ConfirmAccountDeletion, type: :handler do
  let(:user) do
    create_newflow_user('user@openstax.org', 'password').tap do |u|
      u.refresh_account_deletion_token(expiration_period: 1.day)
      u.save!
    end
  end

  it 'errors when token is blank' do
    result = described_class.handle(caller: AnonymousUser.instance, params: { token: '' })
    expect(result).to have_routine_error(:token_blank)
  end

  it 'errors when token is not found' do
    result = described_class.handle(caller: AnonymousUser.instance, params: { token: 'nope' })
    expect(result).to have_routine_error(:unknown_account_deletion_token)
  end

  it 'errors when token is expired' do
    user.update_columns(account_deletion_token_expires_at: 1.hour.ago)
    result = described_class.handle(caller: AnonymousUser.instance, params: { token: user.account_deletion_token })
    expect(result).to have_routine_error(:expired_account_deletion_token)
  end

  it 'soft-deletes the user when the token is valid' do
    described_class.call(caller: AnonymousUser.instance, params: { token: user.account_deletion_token })
    expect(user.reload.is_deleted).to eq(true)
  end

  it 'cannot be used twice' do
    token = user.account_deletion_token
    described_class.call(caller: AnonymousUser.instance, params: { token: token })

    result = described_class.handle(caller: AnonymousUser.instance, params: { token: token })
    expect(result).to have_routine_error(:unknown_account_deletion_token)
  end
end
