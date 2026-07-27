require 'rails_helper'

describe FindOrCreateUser do
  context "Given an email" do

    context "of existing user" do

      it "returns the existing user when the email is verified" do
        user = FactoryBot.create :user_with_emails, emails_count: 1
        found = described_class.call(
          email: user.contact_infos.first.value, already_verified: true
        ).outputs.user
        expect(found).to eq(user)
      end

      it "does not return the existing user when the email is not verified" do
        user = FactoryBot.create :user_with_emails, emails_count: 1
        result = described_class.call(email: user.contact_infos.first.value, already_verified: false)
        expect(result.outputs.user).not_to eq(user)
        expect(result.errors).not_to be_empty
      end

    end

    context "that doesn't exist" do

      it "creates a new user with the email" do
        expect {
          newuser = described_class.call(
            email:"anunusedemail@example.com",
            first_name: Faker::Name.first_name, last_name: Faker::Name.last_name, already_verified: false
          ).outputs.user
          expect(newuser.contact_infos.first.value).to eq("anunusedemail@example.com")
        }.to change(User,:count).by(1)
      end

      it "sends an invitation email" do
          expect do
            described_class.call(
              email:"anunusedemail@example.com",
              first_name: Faker::Name.first_name, last_name: Faker::Name.last_name, already_verified: false
            ).outputs.user
            perform_enqueued_jobs
            email = ActionMailer::Base.deliveries.last
            expect(email.subject).to match('You have been invited to join OpenStax')
          end.to change { ActionMailer::Base.deliveries.count }.by(1)
      end

    end

  end

  context "given an external_id" do

    context "that doesn't exist" do

      it 'sets the first name and last name' do
        expect {
          new_user = described_class.call(
            external_id: 'some-platform/12345', email: 'anunusedemail@example.com',
            first_name: 'Bob', last_name: 'Smith'
          ).outputs.user
          expect(new_user.first_name).to eq('Bob')
          expect(new_user.last_name).to eq('Smith')
        }.to change { User.count }.by(1)
      end

      it 'sets is_test' do
        is_test = [true, false].sample
        new_user = described_class.call(
          external_id: 'some-platform/12345', email: 'anunusedemail@example.com',
          first_name: Faker::Name.first_name, last_name: Faker::Name.last_name,
          is_test: is_test
        ).outputs.user
        expect(new_user.is_test).to eq is_test
        expect(new_user.reload.is_test).to eq is_test
      end

      it "finds the existing user by verified email instead of creating a duplicate" do
        existing_user = FactoryBot.create :user_with_emails, emails_count: 1
        found = described_class.call(
          external_id: 'some-platform/12345',
          email: existing_user.contact_infos.first.value, already_verified: true
        ).outputs.user
        expect(found).to eq(existing_user)
      end

      it "does not find the existing user by an unverified email" do
        existing_user = FactoryBot.create :user_with_emails, emails_count: 1
        result = described_class.call(
          external_id: 'some-platform/12345',
          email: existing_user.contact_infos.first.value, already_verified: false
        )
        expect(result.outputs.user).not_to eq(existing_user)
        expect(result.errors).not_to be_empty
      end

    end

  end

  context "given invalid options" do

    it "returns errors" do
      results = described_class.call(abunchofjunk:"glub")
      expect(results.errors.length).to eq(1)
      expect(results.errors.first.code).to eq(:invalid_input)
    end

  end

end
