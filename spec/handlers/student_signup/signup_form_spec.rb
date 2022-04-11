require 'rails_helper'

module StudentSignup
  describe SignupForm, type: :handler do
    context 'when success' do
      before(:all) do
        DatabaseCleaner.start
        load('db/seeds.rb')
      end

      after(:all) { DatabaseCleaner.clean }

      let(:handler_call) do
        described_class.call(params: params)
      end

      let(:params) do
        {
          signup: {
            first_name: Faker::Name.first_name,
            last_name: Faker::Name.last_name,
            email: email,
            password: Faker::Internet.password(min_length: 8),
            terms_accepted: true,
            newsletter: true,
            contract_1_id: FinePrint::Contract.first.id,
            contract_2_id: FinePrint::Contract.second.id,
            role: :student
          }
        }
      end

      let(:email) do
        Faker::Internet.free_email
      end

      it 'creates an (unverified) user with role = student' do
        expect { handler_call }.to change { User.where(state: 'unverified', role: 'student').count }
      end

      it 'creates an identity' do
        expect { handler_call }.to change { Identity.count }
      end

      it 'creates an authentication with provider = identity' do
        expect { handler_call }.to change { Authentication.where(provider: 'identity').count }
      end

      it 'agrees to terms of use and privacy policy when contracts_required' do
        expect {
          described_class.call(params: params, contracts_required: true)
        }.to change {
          FinePrint::Signature.count
        }.by(2)
      end

      it 'doesnt agrees to terms of use and privacy policy when contracts NOT required' do
        expect {
          described_class.call(params: params, contracts_required: false)
        }.not_to change {
          FinePrint::Signature.count
        }
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

      it 'stores selection in User whether to receive newsletter or not' do
        expect(User.new.receive_newsletter).to be_falsey
        handler_call
        expect(User.last.receive_newsletter).to be(true)
      end

      it 'outputs a user' do
        expect(handler_call.outputs.user).to be_present
      end
    end

    context 'when failure because a user with the given email address already exists' do
      before do
        create_newflow_user(email)
      end

      let(:email) do
        Faker::Internet.free_email
      end

      let(:params) do
        {
          signup: {
            first_name: Faker::Name.first_name,
            last_name: Faker::Name.last_name,
            email: email,
            password: Faker::Internet.password(min_length: 8),
            terms_accepted: true,
            newsletter: true,
            contract_1_id: 1,
            contract_2_id: 2,
            role: 'student'
          }
        }
      end

      let(:result) do
        described_class.call(params: params)
      end

      example do
        expect(result.errors.first.message).to eq(I18n.t(:"login_signup_form.email_address_taken"))
        expect(result.errors).to have_offending_input(:email)
      end
    end

    context 'when user leaves input fields empty' do
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
            contract_2_id: 2,
            role: 'student'
          }
        }
      end

      let(:result) do
        allow_any_instance_of(described_class).to receive(:required_params).and_return([:email])
        described_class.call(params: params)
      end

      example do
        expect(result.errors).to have_offending_input(:email)
      end
    end

    context 'when failure because the domain provider is invalid' do
      before do
        EmailDomainMxValidator.strategy = EmailDomainMxValidator::FakeStrategy.new(expecting: false)
      end

      let(:params) do
        {
          signup: {
            first_name: Faker::Name.first_name,
            last_name: Faker::Name.last_name,
            email: 'user@baddomain.com',
            password: Faker::Internet.password(min_length: 8),
            terms_accepted: true,
            newsletter: true,
            contract_1_id: 1,
            contract_2_id: 2,
            role: 'student'
          }
        }
      end

      example do
        result = described_class.call(params: params)
        expect(result.errors).to have_offending_input(:email)
        expect(result.errors.first.message).to eq(
          I18n.t(:"login_signup_form.invalid_email_provider", email: 'user@baddomain.com')
        )
      end
    end
  end
end
