require 'spec_helper'

describe Authentication do
  
  let!(:authentication) { FactoryGirl.create(:authentication) }

  context "when an authentication exists" do
    it "is returned by by_provider_and_uid" do
      value = Authentication.find_by_provider_and_uid(
        authentication.provider, authentication.uid)
      expect(value).to eq authentication
    end

    it "is returned by by_provider_and_uid!" do
      value = nil
      expect{value = Authentication.find_or_create_by_provider_and_uid(
        authentication.provider, authentication.uid)}
            .not_to change{Authentication.count}
      expect(value).to eq authentication
    end
  end

  context "when an authentication doesn't exist" do
    it "returns nil from by_provider_and_uid" do
      expect(Authentication.find_by_provider_and_uid("foo", "bar")).to be_nil
    end

    it "is created by by_provider_and_uid!" do
      provider = SecureRandom.hex(4)
      value = nil
      expect{value = Authentication.find_or_create_by_provider_and_uid(
        provider, "42")}.to change{Authentication.count}.by(1)
      expect(value.class).to eq Authentication
      expect(value.provider).to eq provider
      expect(value.uid).to eq "42"
    end
  end

end