require 'rails_helper'

describe SendResetPasswordEmail, type: :handler do
  let(:user) do
    create_newflow_user('user@openstax.org', 'password')
  end

  let(:params) do
    {
      forgot_password_form: {
        email: 'user@openstax.org'
      }
    }
  end

  context 'when user is passed-in' do
    it 'sends a password reset email' do
      expect_any_instance_of(NewflowMailer).to receive(:reset_password_email).and_call_original
      described_class.call(params: {}, caller: user)
      perform_enqueued_jobs
    end
  end

  context 'when email param is passed-in, no user' do
    it 'updates the password for the user found by email address' do
      user # create it
      expect_any_instance_of(NewflowMailer).to receive(:reset_password_email).and_call_original
      described_class.call(params: params, caller: AnonymousUser.instance)
      perform_enqueued_jobs
    end
  end

  it 'creates a login token for user' do
    expect_any_instance_of(User).to receive(:refresh_login_token).and_call_original
    described_class.call(caller: user, params: {})
  end

  it 'resets the login token for user when it has one' do
    expect(user.login_token).to be(nil)
    described_class.call(params: {}, caller: user)
    expect(user.login_token).to be_a(String)
  end

  context 'when the account exists but its email is unverified' do
    let!(:unverified_user) do
      user = FactoryBot.create(:user, state: User::UNVERIFIED, is_newflow: true, role: 'student')
      FactoryBot.create(:email_address, user: user, value: 'unverified@openstax.org', verified: false)
      user
    end

    let(:params) do
      { forgot_password_form: { email: 'unverified@openstax.org' } }
    end

    it 'finds the user instead of erroring cannot_find_user' do
      result = described_class.handle(caller: AnonymousUser.instance, params: params)
      expect(result).not_to have_routine_error(:cannot_find_user)
      expect(result.outputs.user).to eq(unverified_user)
    end

    it 'resends the email verification and flags needs_email_verification' do
      expect_any_instance_of(NewflowMailer).to receive(:signup_email_confirmation).and_call_original
      result = described_class.handle(caller: AnonymousUser.instance, params: params)
      expect(result.outputs.needs_email_verification).to be(true)
      perform_enqueued_jobs
    end

    it 'does not send a password reset email' do
      expect_any_instance_of(NewflowMailer).not_to receive(:reset_password_email)
      described_class.handle(caller: AnonymousUser.instance, params: params)
      perform_enqueued_jobs
    end

    it 'outputs the exact address the verification was sent to' do
      FactoryBot.create(:email_address, user: unverified_user, value: 'other@openstax.org', verified: false)
      params[:forgot_password_form][:email] = 'other@openstax.org'

      result = described_class.handle(caller: AnonymousUser.instance, params: params)
      expect(result.outputs.email_address.value).to eq('other@openstax.org')
    end

    it 'sends verification to only the matched address, not every unverified one' do
      FactoryBot.create(:email_address, user: unverified_user, value: 'other@openstax.org', verified: false)
      ActionMailer::Base.deliveries.clear

      described_class.handle(caller: AnonymousUser.instance, params: params)
      perform_enqueued_jobs

      expect(ActionMailer::Base.deliveries.flat_map(&:to)).to eq(['unverified@openstax.org'])
    end
  end

  # The account that produced support case 00128408 was created in 2021 and
  # abandoned at the PIN screen; whatever state it ended up in, nobody ever
  # proved control of the address, and reset is the only door back in.
  context 'when the account never verified its email but is not in the unverified state' do
    let!(:stale_user) do
      user = FactoryBot.create(:user, state: User::ACTIVATED, is_newflow: true, role: 'instructor')
      FactoryBot.create(:email_address, user: user, value: 'abandoned@openstax.org', verified: false)
      user
    end

    let(:params) do
      { forgot_password_form: { email: 'abandoned@openstax.org' } }
    end

    it 'resends the email verification rather than erroring cannot_find_user' do
      result = described_class.handle(caller: AnonymousUser.instance, params: params)

      expect(result).not_to have_routine_error(:cannot_find_user)
      expect(result.outputs.user).to eq(stale_user)
      expect(result.outputs.needs_email_verification).to be(true)
      expect(result.outputs.email_address.value).to eq('abandoned@openstax.org')
    end
  end

  context 'when the account is unverified but has no unverified address left' do
    # `ConfirmByPin` returns without error for an already-confirmed address, so a
    # user routed to the PIN form in this state would be signed in by any PIN.
    let!(:half_claimed_user) do
      user = FactoryBot.create(:user, state: User::UNVERIFIED, is_newflow: true, role: 'student')
      FactoryBot.create(:email_address, user: user, value: 'claimed@openstax.org', verified: true)
      user
    end

    let(:params) do
      { forgot_password_form: { email: 'claimed@openstax.org' } }
    end

    it 'does not flag needs_email_verification' do
      result = described_class.handle(caller: AnonymousUser.instance, params: params)
      expect(result.outputs.needs_email_verification).to be_nil
    end

    it 'is not reachable by username either' do
      result = described_class.handle(
        caller: AnonymousUser.instance,
        params: { forgot_password_form: { email: half_claimed_user.username } }
      )
      expect(result.outputs.needs_email_verification).to be_nil
      expect(result).to have_routine_error(:cannot_find_user)
    end
  end

  context 'when no user found' do
    let(:params) do
    {
      forgot_password_form: {
        email: 'noone@openstax.org'
      }
    }
  end

    it 'adds error cannot_find_user' do
      result = described_class.handle(caller: AnonymousUser.instance, params: params)
      expect(result).to have_routine_error(:cannot_find_user)
    end
  end

  context 'when no email present and no logged in user' do
    let(:params) do
      {
        forgot_password_form: {
          email: nil
        }
      }
    end

    subject(:result) do
      described_class.call(params: params, caller: AnonymousUser.instance)
    end

    it 'returns fatal error email is blank' do
      expect(result).to have_routine_error(:email_is_blank)
    end
  end
end
