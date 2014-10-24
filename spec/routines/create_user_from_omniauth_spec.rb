require 'spec_helper'

describe CreateUserFromOmniauth do
  let(:nickname) { 'first name+_middle_.last~name_' + 'a' * 100 }

  context 'when auth provider is unknown' do
    it 'raises an error' do
      auth = {}
      expect {
        CreateUserFromOmniauth.call(auth)
      }.to raise_error(IllegalArgument)
    end
  end

  context 'when auth provider is identity' do
    it 'raises an error because we should not get here' do
      auth = { provider: 'identity' }
      expect {
        CreateUserFromOmniauth.call(auth)
      }.to raise_error(Unexpected)
    end
  end

  context 'when auth provider is facebook' do
    it 'normalizes usernames' do
      auth = {
        provider: 'facebook',
        info: {
          nickname: nickname,
        },
      }

      expect_any_instance_of(CreateUserFromOmniauth).to receive(:run) do |create_user, args|
        @normalized_nickname = args.delete(:username)
        expect(create_user).to eq(CreateUser)
        expect(args).to eq({ first_name: nil, last_name: nil, full_name: nil, ensure_no_errors: true })
      end

      CreateUserFromOmniauth.call(auth)
      user = User.new
      user.username = @normalized_nickname
      expect(user).to be_valid
    end
  end

  context 'when auth provider is twitter' do
    it 'normalizes usernames' do
      auth = {
        provider: 'twitter',
        info: {
          nickname: nickname,
        },
      }

      expect_any_instance_of(CreateUserFromOmniauth).to receive(:run) do |create_user, args|
        @normalized_nickname = args.delete(:username)
        expect(create_user).to eq(CreateUser)
        expect(args).to eq({ ensure_no_errors: true })
      end

      CreateUserFromOmniauth.call(auth)
      user = User.new
      user.username = @normalized_nickname
      expect(user).to be_valid
    end
  end

  context 'when auth provider is google' do
    it 'normalizes usernames' do
      auth = {
        provider: 'google_oauth2',
        info: {
          name: nickname,
        },
      }

      expect_any_instance_of(CreateUserFromOmniauth).to receive(:run) do |create_user, args|
        @normalized_nickname = args.delete(:username)
        expect(create_user).to eq(CreateUser)
        expect(args).to eq({ ensure_no_errors: true })
      end

      CreateUserFromOmniauth.call(auth)
      user = User.new
      user.username = @normalized_nickname
      expect(user).to be_valid
    end
  end

end
