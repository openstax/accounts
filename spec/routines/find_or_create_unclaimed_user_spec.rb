require 'spec_helper'

describe FindOrCreateUnclaimedUser do

  let(:user) { FactoryGirl.create :user, state: 'unclaimed' }

  context "Given an email" do

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

      it "sends an invitation email" do
          expect {
            FindOrCreateUnclaimedUser.call(email:"anunusedemail@example.com").outputs.user
            email = ActionMailer::Base.deliveries.last
            expect(email.subject).to match('You have been invited to join OpenStax')
          }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end

    end

  end

  context "given a username" do

    context "of existing unclaimed user" do

      it "returns that user" do
        found = FindOrCreateUnclaimedUser.call(username: user.username).outputs.user
        expect(found).to eq(user)
      end

      context "and a password" do

        it "does not set the password" do
          found = FindOrCreateUnclaimedUser.call(
            username: user.username, password:"apassword123",
            password_confirmation: "apassword123"
          ).outputs.user
          expect(found.identity).to be_nil
        end
      end

    end

    context "that doesn't exist" do

      it "creates a new user with that username" do
        expect {
          new_user=FindOrCreateUnclaimedUser.call(
            username: "bobsmith", email:"anunusedemail@example.com"
          ).outputs.user
          expect(new_user.username).to eq("bobsmith")
          expect(new_user.contact_infos.first.value).to eq("anunusedemail@example.com")
        }.to change(User,:count).by(1)
      end

      context "and a password" do

        it "sets the password" do
          new_user=FindOrCreateUnclaimedUser.call(
            password:'password123', password_confirmation: 'password123', username: "bobsmith",
            email:"anunusedemail@example.com"
          ).outputs.user
          expect(new_user.reload.identity.authenticate('password123')).to be_true
        end

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
