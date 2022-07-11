require 'rails_helper'

describe FindOrCreateUnclaimedUser do

  let(:user) { FactoryBot.create :user, state: 'unclaimed' }

  context "Given an email" do

    context "of existing user" do

      it "returns the existing user" do
        user = FactoryBot.create :user_with_emails, emails_count: 1
        found = FindOrCreateUnclaimedUser.call(email:user.contact_infos.first.value).outputs.user
        expect(found).to eq(user)
      end

    end

    context "that doesn't exist" do

      it "creates a new user with the email" do
        expect {
          newuser = FindOrCreateUnclaimedUser.call(
            email:"anunusedemail@example.com",
            first_name: Faker::Name.first_name, last_name: Faker::Name.last_name, already_verified: false
          ).outputs.user
          expect(newuser.contact_infos.first.value).to eq("anunusedemail@example.com")
        }.to change(User,:count).by(1)
      end

      it "sends an invitation email" do
          expect do
            FindOrCreateUnclaimedUser.call(
              email:"anunusedemail@example.com",
              first_name: Faker::Name.first_name, last_name: Faker::Name.last_name, already_verified: false
            ).outputs.user
            email = ActionMailer::Base.deliveries.last
            expect(email.subject).to include('[OpenStax] Use PIN')
          end.to change { ActionMailer::Base.deliveries.count }.by(1)
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
          new_user = FindOrCreateUnclaimedUser.call(
            username: "bobsmith", email:"anunusedemail@example.com",
            first_name: Faker::Name.first_name, last_name: Faker::Name.last_name, already_verified: false
          ).outputs.user
          expect(new_user.username).to eq("bobsmith")
          expect(new_user.contact_infos.first.value).to eq("anunusedemail@example.com")
        }.to change(User,:count).by(1)
      end

      it 'sets the first name and last name' do
        expect {
          new_user = FindOrCreateUnclaimedUser.call(
            username: 'bobsmith', email: 'anunusedemail@example.com',
            first_name: 'Bob', last_name: 'Smith'
          ).outputs.user
          expect(new_user.username).to eq('bobsmith')
          expect(new_user.first_name).to eq('Bob')
          expect(new_user.last_name).to eq('Smith')
        }.to change { User.count }.by(1)
      end

      context "and a password" do

        it "sets the password" do
          new_user = FindOrCreateUnclaimedUser.call(
            email:"anunusedemail@example.com",
            password:'password123', password_confirmation: 'password123', username: "bobsmith",
            first_name: Faker::Name.first_name, last_name: Faker::Name.last_name, already_verified: false
          ).outputs.user
          expect(new_user.reload.identity.authenticate('password123')).to be_truthy
        end

      end

      context 'and is_test' do
        it 'sets is_test' do
          is_test = [true, false].sample
          new_user = FindOrCreateUnclaimedUser.call(
            username: 'bobsmith', email: 'anunusedemail@example.com',
            first_name: Faker::Name.first_name, last_name: Faker::Name.last_name,
            is_test: is_test
          ).outputs.user
          expect(new_user.is_test).to eq is_test
          expect(new_user.reload.is_test).to eq is_test
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
