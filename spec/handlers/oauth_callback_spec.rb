require 'rails_helper'

RSpec.describe OauthCallback, type: :handler do
  let(:email) { Faker::Internet.email }

  context 'when existing authentication found' do
    let(:oauth_user_info) {
      { email: email, name: Faker::Name.name }
    }

    let(:user) {
      create_user(email)
    }

    let(:auth) {
      FactoryBot.create(:authentication, user: user, provider: 'facebook')
    }

    let(:request) {
      MockOmniauthRequest.new 'facebook', auth.uid, oauth_user_info
    }

    let(:subject) {
      described_class.call(request: request)
    }

    it 'simply outputs the user' do
      expect(subject.outputs.user).to eq User.last
    end
  end

  context 'when no authentication found, but verified user found' do
    before do
      create_user(email)
    end

    let(:oauth_user_info) {
      { email: email, name: Faker::Name.name }
    }

    let(:request) {
      MockOmniauthRequest.new 'facebook', Faker::Internet.uuid, oauth_user_info
    }

    let(:subject) {
      described_class.call(request: request)
    }

    it 'creates an authentication' do
      expect {
        subject
      }.to change(Authentication, :count)
    end

    it 'transfers the authentication to the user' do
      expect_any_instance_of(TransferAuthentications).to receive(:call).and_call_original
      subject
    end

    it 'outputs the user' do
      expect(subject.outputs.user).to eq User.last
    end
  end

  context 'when no authentication found, and no verified user found' do
    let(:oauth_user_info) {
      { email: email, name: Faker::Name.name }
    }

    let(:request) {
      MockOmniauthRequest.new 'facebook', Faker::Internet.uuid, oauth_user_info
    }

    describe 'sign up a new user' do
      it 'creates a user' do
        expect {
          described_class.call(request: request)
        }.to change(User, :count)
      end

      it 'creates an authentication' do
        expect { described_class.call(request: request) }.to(
          change { Authentication.count }.by(1)
        )
      end

      it 'creates an email address as verified' do
        expect { described_class.call(request: request) }.to(
          change { EmailAddress.where(verified: true).count }.by(1)
        )
      end
    end
  end

  context 'when no authentication found and the response from social provider does not include email' do
    before do
      create_user(email)
    end

    let(:oauth_user_info) {
      { email: nil, name: Faker::Name.name }
    }

    let(:request) {
      MockOmniauthRequest.new 'facebook', Faker::Internet.uuid, oauth_user_info
    }

    let(:process_request) {
      described_class.call(request: request)
    }

    it 'creates a new user' do
      expect { process_request }.to(
        change { User.count }.by(1)
      )
    end

    describe 'the new user' do
      subject(:the_new_user) { process_request.outputs.user }

      it 'has its state set to UNVERIFIED' do
        expect(the_new_user.state).to eq(User::UNVERIFIED)
      end
    end

    it 'creates an authentication' do
      expect { process_request }.to(
        change { Authentication.count }.by(1)
      )
    end

    it 'does not create an email address' do
      expect { process_request }.to_not(
        change { EmailAddress.count }
      )
    end
  end

  context 'when there is a logged in user' do
    before do
      FactoryBot.create(:identity, user: user)
      FactoryBot.create(:email_address, user: user, value: email)
    end

    let(:oauth_user_info) do
      { email: email, name: Faker::Name.name }
    end

    let(:user) do
      FactoryBot.create(:user, :terms_agreed)
    end

    let(:process_request) do
      described_class.call(request: request, logged_in_user: user)
    end

    let(:request) do
      MockOmniauthRequest.new 'google_oauth2', Faker::Internet.uuid, oauth_user_info
    end

    subject(:user_authentications) { user.authentications }

    context 'when the email address is same as the one the user already owns' do
      it 'adds the authentication to the user' do
        expect { process_request }.to change(user_authentications, :count).by(1)
      end
    end

    context 'when the email address is different than the one the user already owns' do
      before do
        oauth_user_info[:email] = Faker::Internet.email
      end

      let(:email) { Faker::Internet.email }

      it 'adds the authentication to the user' do
        expect { process_request }.to change(user_authentications, :count).by(1)
      end
    end

    context 'when the email address is already taken' do
      it 'results in an error' do
        expect {
          u = FactoryBot.create(:user)
          FactoryBot.create(:email_address, user: u, value: oauth_user_info[:email], verified: true)
          process_request
          create_email_address_for(create_user('other_user'), 'user@example.com', '989188')
        }.to raise_error(ActiveRecord::RecordInvalid, /already been taken/)
      end
    end

    context 'when the email address from the social provider is blank' do
      before do
        oauth_user_info[:email] = nil
      end

      it 'adds the authentication to the user' do
        expect { process_request }.to change(user_authentications, :count).by(1)
      end
    end
  end
end
