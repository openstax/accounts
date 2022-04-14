require 'rails_helper'

describe OmniauthData do
  context 'when auth provider is facebook' do
    it 'stores user information' do
      auth_hash = OmniAuth::AuthHash.new provider: 'facebook', uid: '1234567890'
      auth_hash.extra = {
        raw_info: {
          email: 'user@example.com',
          first_name: 'User',
          last_name: 'One',
          gender: 'female',
          id: '1234567890',
          languages: [{id: '106059522759137', name: 'English'}],
          link: 'https://www.facebook/user.one',
          locale: 'en_US',
          location: {id: '116045151742300', name: 'Munich, Germany'},
          name: 'User N. One',
          timezone: 1,
          updated_time: '2013-07-28T18:22:46+0000',
          username: 'user1',
          verifeid: 'true',
        },
      }
      auth_hash.info = {
        email: 'user@example.com',
        first_name: 'User',
        image: 'http://graph.facebook.com/1234567890/picture?type=square',
        last_name: 'One',
        location: 'Munich, Germany',
        name: 'User N. One',
        nickname: 'user1',
        urls: {Facebook: 'https://www.facebook.com/user.one'},
        verified: true
      }
      data = OmniauthData.new(auth_hash)

      expect(data.provider).to eq 'facebook'
      expect(data.uid).to eq '1234567890'
      expect(data.name).to eq 'User N. One'
      expect(data.nickname).to eq 'user1'
      expect(data.first_name).to eq 'User'
      expect(data.last_name).to eq 'One'
      expect(data.email).to eq 'user@example.com'
    end
  end

  context 'when auth provider is google' do
    it 'stores user information' do
      user = FactoryBot.create :user
      auth_hash = OmniAuth::AuthHash.new provider: 'google', uid: '12345678901234567890'
      auth_hash.extra = {
        id_token: 'SoMeLoNgRaNdOmStRiNg',
        raw_info: {
          email: 'user@example.com',
          family_name: 'One',
          gender: 'female',
          given_name: 'User',
          hd: 'example.com',
          id: '1234567890',
          link: 'https://plus.google.com/1234567890',
          locale: 'en',
          name: 'User N. One',
          picture: 'https://lh5.googleusercontent.com/xxxxxx/yyyyy/photo.jpg',
          verified_email: true,
        },
      }
      auth_hash.info = {
        email: 'user@example.com',
        first_name: 'User',
        image: 'https://lh5.googleusercontent.com/xxxxxx/yyyyy/photo.jpg',
        last_name: 'One',
        name: 'User N. One',
        urls: { Google: 'https://plus.google.com/1234567890' },
      }
      data = OmniauthData.new(auth_hash)

      expect(data.provider).to eq 'google'
      expect(data.uid).to eq '12345678901234567890'
      expect(data.name).to eq 'User N. One'
      expect(data.nickname).to eq 'User N. One'
      expect(data.first_name).to eq 'User'
      expect(data.last_name).to eq 'One'
      expect(data.email).to eq 'user@example.com'
    end
  end

  context 'when auth provider is identity' do
    it 'does not error out' do
      auth = { provider: 'identity' }
      expect {
        data = OmniauthData.new(auth)
      }.not_to raise_error
    end
  end

  context 'when auth provider is unknown' do
    it 'raises an error' do
      auth = {}
      expect {
        data = OmniauthData.new(auth)
      }.to raise_error(IllegalArgument)
    end
  end
end
