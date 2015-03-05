require 'spec_helper'

describe CreateUserFromOmniauthData do
  let(:nickname) { 'first name+_middle_.last~name_' + 'a' * 100 }

  context 'when auth provider is facebook' do
    it 'passes nickname to CreateUser' do
      auth = {
        provider: 'facebook',
        info: {
          nickname: nickname
        },
      }
      data = OmniauthData.new(auth)

      expect_any_instance_of(CreateUserFromOmniauthData).to receive(:run) do |create_user, args|
        @username = args[:username]
        expect(create_user).to eq(CreateUser)
        expect(args).to include({ ensure_no_errors: true })
      end

      CreateUserFromOmniauthData.call(data)
      expect(@username).to eq nickname
    end
  end

  context 'when auth provider is twitter' do
    it 'passes nickname to CreateUser' do
      auth = {
        provider: 'twitter',
        info: {
          nickname: nickname,
        },
      }
      data = OmniauthData.new(auth)

      expect_any_instance_of(CreateUserFromOmniauthData).to receive(:run) do |create_user, args|
        @username = args[:username]
        expect(create_user).to eq(CreateUser)
        expect(args).to include({ ensure_no_errors: true })
      end

      CreateUserFromOmniauthData.call(data)
      expect(@username).to eq nickname
    end
  end

  context 'when auth provider is google' do
    it 'passes the name as nickname to CreateUser if nickname is nil' do
      auth = {
        provider: 'google_oauth2',
        info: {
          nickname: nil,
          name: "Billy O\'Connor"
        },
      }
      data = OmniauthData.new(auth)

      expect_any_instance_of(CreateUserFromOmniauthData).to receive(:run) do |create_user, args|
        @username = args[:username]
        expect(create_user).to eq(CreateUser)
        expect(args).to include({ full_name: "Billy O\'Connor",
                                  ensure_no_errors: true })
      end

      CreateUserFromOmniauthData.call(data)
      expect(@username).to eq "Billy O\'Connor"
    end
  end

  context 'when auth provider is identity' do
    it 'raises an error because we should not get here' do
      auth = { provider: 'identity' }
      data = OmniauthData.new(auth)
      expect {
        CreateUserFromOmniauthData.call(data)
      }.to raise_error(Unexpected)
    end
  end

end
