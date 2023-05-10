require 'rails_helper'

RSpec.describe CreateExternalUserCredentials, type: :handler do
  let(:user)  do
    FactoryBot.create :user, receive_newsletter: false,
                             role: User::UNKNOWN_ROLE,
                             state: User::EXTERNAL
  end

  let(:email) { Faker::Internet.free_email }

  let(:params) do
    {
      signup: {
        first_name: 'Testy',
        last_name: 'McTestFace',
        email: email,
        password: Faker::Internet.password(min_length: 8),
        terms_accepted: true,
        newsletter: true,
        contract_1_id: FinePrint::Contract.first.id,
        contract_2_id: FinePrint::Contract.second.id
      }
    }
  end

  let(:handler_call) { described_class.call caller: user, params: params }

  context 'when successful' do
    before(:all) do
      DatabaseCleaner.start
      load('db/seeds.rb')
    end

    after(:all) { DatabaseCleaner.clean }

    it 'creates an identity' do
      expect { handler_call }.to change { Identity.count }
    end

    it 'creates an authentication with provider = identity' do
      expect { handler_call }.to change { Authentication.where(provider: 'identity').count }
    end

    it 'creates an email address' do
      expect { handler_call }.to change { EmailAddress.count }
    end

    it 'sends a confirmation email' do
      expect_any_instance_of(NewflowMailer).to(
        receive(:signup_email_confirmation).with(
          hash_including({ email_address: an_instance_of(EmailAddress) })
        )
      )
      handler_call
    end

    it "sets the User's role to student" do
      expect(user).to be_unknown_role
      handler_call
      expect(user.reload).to be_student
    end

    it 'stores selection in User whether to receive newsletter or not' do
      expect(user.receive_newsletter).to eq false
      handler_call
      expect(user.reload.receive_newsletter).to eq true
    end

    it 'agrees to terms of use and privacy policy' do
      expect { handler_call }.to change { FinePrint::Signature.count }.by(2)
    end

    it 'outputs a user' do
      expect(handler_call.outputs.user).to be_present
    end
  end

  context 'when failure because the user is not external' do
    before { user.update_attribute :state, User::ACTIVATED }

    it 'throws a Lev::SecurityTransgression' do
      expect { handler_call }.to raise_error(Lev::SecurityTransgression)
    end
  end

  context 'when failure because a user with the given email address already exists' do
    before { create_newflow_user(email) }

    it 'returns an error' do
      expect(handler_call.errors.first.message).to eq(I18n.t(:"login_signup_form.email_address_taken"))
      expect(handler_call.errors).to have_offending_input(:email)
    end
  end

  context 'when failure because user leaves input fields empty' do
    let(:params) do
      {
        signup: {
          first_name: nil,
          last_name: nil,
          email: nil,
          password: nil,
          terms_accepted: true,
          newsletter: true,
          contract_1_id: 1,
          contract_2_id: 2
        }
      }
    end

    it 'returns an error' do
      allow_any_instance_of(described_class).to receive(:required_params).and_return([:email])
      expect(handler_call.errors).to have_offending_input(:email)
    end
  end

  context 'when failure because the domain provider is invalid' do
    let(:email) { 'user@baddomain.com' }

    before do
      EmailDomainMxValidator.strategy = EmailDomainMxValidator::FakeStrategy.new(expecting: false)
    end

    it 'returns an error' do
      expect(handler_call.errors).to have_offending_input(:email)
      expect(handler_call.errors.first.message).to eq(
        I18n.t(:"login_signup_form.invalid_email_provider", email: email)
      )
    end
  end
end
