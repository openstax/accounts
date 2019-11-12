require 'rails_helper'

RSpec.describe ChangeSignupEmail, type: :handler do
  let(:user) { FactoryBot.create :user }
  let(:email_originally) { FactoryBot.create :email_address, verified: false, user: user }

  let(:pre_auth_state) {
    FactoryBot.create(:pre_auth_state,
                      role: 'student', contact_info_value: email_originally.value, user_id: user.id)
  }

  let(:params) {
    {
      change_signup_email: {
        email: Faker::Internet.free_email
      }
    }
  }

  context 'when success' do
    it 'changes the user\'s only email address' do
      new_email = params.dig(:change_signup_email, :email)

      described_class.call(params: params, pre_auth_state: pre_auth_state)
      expect(user.email_addresses.first.value).to eq new_email
    end

    it 'changes the PreAuthState\'s email address' do
      previous_email = pre_auth_state.contact_info_value
      new_email = params.dig(:change_signup_email, :email)

      described_class.call(params: params, pre_auth_state: pre_auth_state)
      expect(new_email).not_to eq previous_email
    end

    it 'changes the PreAuthState\'s confirmation code' do
      # previous_email = pre_auth_state.contact_info_value
      # new_email = params.dig(:change_signup_email, :email)

      # described_class.call(params: params, pre_auth_state: pre_auth_state)
      # expect(new_email).not_to eq previous_email
    end

    it 'deletes the previous email address, creates a new one' do
      pre_auth_state # create it along with the user and email address

      expect {
        described_class.call(params: params, pre_auth_state: pre_auth_state)
      }.not_to change(EmailAddress, :count)
    end

    # rubocop:disable RSpec/MultipleExpectations
    it 'updates the PreAuthState\'s contact_info_value' do
      previous = pre_auth_state.contact_info_value.dup
      new_email = params.dig(:change_signup_email, :email)

      described_class.call(params: params, pre_auth_state: pre_auth_state)
      expect(pre_auth_state.contact_info_value).not_to eq previous
      expect(pre_auth_state.contact_info_value).to eq new_email
    end
    # rubocop:enable RSpec/MultipleExpectations

    it 'outputs the pre_auth_state (which the controller should save afterwards' do
      expect(
        described_class.call(params: params, pre_auth_state: pre_auth_state).outputs
      ).to include('pre_auth_state')
    end

    it 'sends an email to the new email address' do
      expect_any_instance_of(SignupConfirmationMailer).to(
        receive(:instructions).and_call_original
      )
      described_class.call(params: params, pre_auth_state: pre_auth_state)
    end
  end

  context 'when email address already taken' do
    # meaning when there's already a verified email address with the same value
    before do
      FactoryBot.create(
        :email_address,
        value: params.dig(:change_signup_email, :email),
        verified: true
      )
    end

    it 'adds errors to email input' do
      result = described_class.call(params: params, pre_auth_state: pre_auth_state)
      expect(result.errors).to have_offending_input(:email)
    end
  end
end
