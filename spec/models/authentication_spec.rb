require 'rails_helper'

describe Authentication do

  let!(:authentication) { FactoryBot.create(:authentication) }

  context "when an authentication exists" do
    it "is returned by by_provider_and_uid" do
      value = Authentication.find_by(provider: authentication.provider, uid: authentication.uid)
      expect(value).to eq authentication
    end

    it "is returned by by_provider_and_uid!" do
      value = nil
      expect{value = Authentication.find_or_create_by(provider: authentication.provider,
        uid: authentication.uid
      )}.not_to change{Authentication.count}
      expect(value).to eq authentication
    end

    it "cannot be created again with the same provider and UID" do
      new_authentication = Authentication.create(provider: authentication.provider,
                                                 uid: authentication.uid)
      expect(new_authentication).not_to be_valid
    end
  end

  context "when an authentication doesn't exist" do
    it "returns nil from by_provider_and_uid" do
      expect(Authentication.find_by(provider: "foo", uid: "bar")).to be_nil
    end

    it "is created by by_provider_and_uid!" do
      provider = SecureRandom.hex(4)
      value = nil
      expect{
        value = Authentication.find_or_create_by(provider: provider, uid: "42"
      )}.to change{Authentication.count}.by(1)
      expect(value.class).to eq Authentication
      expect(value.provider).to eq provider
      expect(value.uid).to eq "42"
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
