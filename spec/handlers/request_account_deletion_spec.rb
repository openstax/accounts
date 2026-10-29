require 'rails_helper'

describe RequestAccountDeletion, type: :handler do
  let(:user) do
    create_newflow_user('user@openstax.org', 'password')
  end

  it 'is not authorized for anonymous users' do
    expect {
      described_class.handle(caller: AnonymousUser.instance, params: {})
    }.to raise_error(Lev::SecurityTransgression)
  end

  it 'sets a fresh account deletion token on the user' do
    expect(user.account_deletion_token).to be_nil
    described_class.call(caller: user, params: {})
    user.reload
    expect(user.account_deletion_token).to be_a(String)
    expect(user.account_deletion_token_expires_at).to be > Time.now
  end

  it 'sends a confirmation email to each verified email address' do
    expect_any_instance_of(NewflowMailer).to receive(:account_deletion_confirmation).and_call_original
    described_class.call(caller: user, params: {})
    perform_enqueued_jobs
  end

  context 'when the user has no verified email addresses' do
    before { user.email_addresses.update_all(verified: false) }

    it 'returns a no_verified_email error' do
      result = described_class.handle(caller: user, params: {})
      expect(result).to have_routine_error(:no_verified_email)
    end
  end
end
