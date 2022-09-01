require 'rails_helper'

RSpec.describe OauthCallback, type: :handler do
  context 'when existing authentication found' do
    let(:email) { Faker::Internet.safe_email }
    let(:oauth_user_info) { { email: email, name: Faker::Name.name } }

    it 'simply outputs the user' do
      user = create_user(email)
      request = MockOmniauthRequest.new 'facebook', user.authentications.first.uid, oauth_user_info
      described_class.call(request: request)
      expect(user).to eq User.last
    end
  end

  context 'when no authentication found, but verified user found' do
    let(:email) { Faker::Internet.safe_email }
    let(:oauth_user_info) { { email: email, name: Faker::Name.name } }
    let(:user) { create_user(email) }
    let(:request) { MockOmniauthRequest.new 'facebook', Faker::Internet.uuid, oauth_user_info }

    it 'creates an authentication' do
      expect(described_class.call(request: request)).to change(Authentication, :count)
    end

    it 'outputs the user' do
      expect(described_class.call(request: request).outputs.user).to eq user
    end
  end

  context 'when no authentication found, and no verified user found' do
    let(:email) { Faker::Internet.safe_email }
    let(:oauth_user_info) { { email: email, name: Faker::Name.name } }

    let(:request) { MockOmniauthRequest.new 'facebook', Faker::Internet.uuid, oauth_user_info }

    describe 'sign up a new user' do
      it 'creates a user' do
        expect { described_class.call(request: request) }.to change(User, :count)
      end

      it 'creates an authentication' do
        expect { described_class.call(request: request) }.to change(Authentication, :count)
      end

      it 'creates an email address as verified' do
        expect { described_class.call(request: request) }.to change(EmailAddress, :count)
      end
    end
  end

  context 'when no authentication found and the response from social provider does not include email' do
    let(:email) { Faker::Internet.safe_email }
    let(:oauth_user_info) { { email: nil, name: Faker::Name.name } }
    let(:request) { MockOmniauthRequest.new 'facebook', Faker::Internet.uuid, oauth_user_info }

    before do
      create_user(email)
      described_class.call(request: request)
    end

    it 'creates a new user' do
      expect { described_class.call(request: request) }.to change(User, :count)
    end

    describe 'the new user' do
      it 'has its state set to unverified and no_faculty_info' do
        described_class.call(request: request)
        expect(User.last.faculty_status).to eq('no_faculty_info')
      end
    end

    it 'creates an authentication' do
      expect { request }.to change(Authentication, :count)
    end

    it 'does not create an email address' do
      expect { request }.to_not change(EmailAddress.count)
    end
  end

  context 'when there is a logged in user' do
    let(:email) { Faker::Internet.safe_email }
    let(:oauth_user_info) { { email: email, name: Faker::Name.name } }
    let(:user) { FactoryBot.create(:user, :terms_agreed) }
    let(:request) { MockOmniauthRequest.new 'google_oauth2', Faker::Internet.uuid, oauth_user_info }

    before do
      FactoryBot.create(:identity, user: user)
      FactoryBot.create(:email_address, user: user, value: email)
    end

    subject(:user_authentications) { user.authentications }

    context 'when the email address is same as the one the user already owns' do
      it 'adds the authentication to the user' do
        expect { described_class.call(request: request) }.to change(user_authentications, :count)
      end
    end

    context 'when the email address is different than the one the user already owns' do
      before do
        oauth_user_info[:email] = Faker::Internet.email
      end

      let(:email) { Faker::Internet.email }

      it 'adds the authentication to the user' do
        expect { described_class.call(request: request) }.to change(user_authentications, :count)
      end
    end

    context 'when the email address is already taken' do
      it 'results in an error' do
        expect {
          u = FactoryBot.create(:user)
          FactoryBot.create(:email_address, user: u, value: oauth_user_info[:email], verified: true)
          described_class.call(request: request)
          create_email_address_for(create_user('other_user'), 'user@example.com', '989188')
        }.to raise_error(ActiveRecord::RecordInvalid, /already been taken/)
      end
    end

    context 'when the email address from the social provider is blank' do
      before do
        oauth_user_info[:email] = nil
      end

      it 'adds the authentication to the user' do
        described_class.call(request: request)
        expect { request }.to change(Authentication, :count).by(1)
      end
    end
  end
end
