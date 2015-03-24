require 'spec_helper'

describe FindOrCreateUnclaimedUser do

  let(:user) { FactoryGirl.create :user, state: 'unclaimed' }

  context "Given an eamil" do

    context "of existing user" do

      it "returns the existing user" do
        AddEmailToUser.call("unclaimeduser@example.com", user, already_verified: true)
        found = FindOrCreateUnclaimedUser.call(email:"unclaimeduser@example.com").outputs.user
        expect(found).to eq(user)
      end

    end

    context "that doesn't exist" do

      it "creates a new user with the email" do
        expect {
          newuser = FindOrCreateUnclaimedUser.call(email:"anunusedemail@example.com").outputs.user
          expect(newuser.contact_infos.first.value).to eq("anunusedemail@example.com")
        }.to change(User,:count).by(1)
      end

    end

  end

  context "given a username" do

    context "of existing user" do

      it "returns that user" do
        found = FindOrCreateUnclaimedUser.call(username: user.username).outputs.user
        expect(found).to eq(user)
      end

    end

    context "that doesn't exist" do

      it "creates a new user with that username" do
        expect {
          newuser = FindOrCreateUnclaimedUser.call(
            username: "bobsmith", email:"anunusedemail@example.com"
          ).outputs.user
          expect(newuser.username).to eq("bobsmith")
          expect(newuser.contact_infos.first.value).to eq("anunusedemail@example.com")
        }.to change(User,:count).by(1)
      end

    end

  end

  context "given invalid options" do

    it "returns errors" do
      results = FindOrCreateUnclaimedUser.call(abunchofjunk:"glub")
      expect(results.errors.length).to eq(1)
      expect(results.errors.first.code).to eq(:invalid_input)
    end

  end
end
