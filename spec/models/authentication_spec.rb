require 'rails_helper'

describe Authentication do
  let!(:authentication) { FactoryBot.create(:authentication) }

  context "when an authentication exists" do
    it "is returned by find_by_provider_and_uid" do
      value = Authentication.find_by_provider_and_uid(authentication.provider, authentication.uid)
      expect(value).to eq authentication
    end

    it "is returned by find_or_create_by" do
      value = nil
      expect do
        value = Authentication.find_or_create_by(
          provider: authentication.provider,
          uid: authentication.uid
        ) do |new_auth|
          new_auth.user = authentication.user
        end
      end.not_to change{Authentication.count}
      expect(value).to eq authentication
    end

    it "cannot be created again with the same provider and UID" do
      new_authentication = Authentication.create(provider: authentication.provider,
                                                 uid: authentication.uid,
                                                 user: authentication.user)
      expect(new_authentication).not_to be_valid
    end
  end

  context "when an authentication doesn't exist" do
    it "returns nil from find_by_provider_and_uid" do
      expect(Authentication.find_by_provider_and_uid("foo", "bar")).to be_nil
    end

    it "is created by find_or_create_by" do
      provider = SecureRandom.hex(4)
      value = nil
      expect do
        value = Authentication.find_or_create_by(provider: provider, uid: '42') do |new_auth|
          new_auth.user = authentication.user
        end
      end.to change{Authentication.count}.by(1)
      expect(value.class).to eq Authentication
      expect(value.provider).to eq provider
      expect(value.uid).to eq '42'
      expect(value.user).to eq authentication.user
    end
  end

  context "when authentications are being deleted" do
    it "isn't deletable when it is the user's last" do
      expect{authentication.destroy}.not_to change{Authentication.count}
    end

    it "is deleted when it isn't the user's last" do
      FactoryBot.create(:authentication, user: authentication.user, provider: 'blah')
      expect{authentication.destroy}.to change{Authentication.count}.by(-1)
    end
  end


end
