require 'rails_helper'

describe FindOrCreateUser do
  context "Given an email" do

    context "of existing user" do

      it "returns the existing user when the email is verified" do
        user = FactoryBot.create :user
        AddEmailToUser.call('verified@example.com', user, already_verified: true)

        found = described_class.call(
          email: 'verified@example.com', already_verified: true
        ).outputs.user
        expect(found).to eq(user)
      end

    end

  end

  context "given an unverified email with no external_id" do

    it "is rejected as invalid input and creates no user" do
      expect {
        result = described_class.call(
          email: "anunusedemail@example.com",
          first_name: Faker::Name.first_name, last_name: Faker::Name.last_name, already_verified: false
        )
        expect(result.errors.first.code).to eq(:invalid_input)
      }.not_to change(User, :count)
    end

  end

  context "given an external_id" do

    context "that doesn't exist" do

      it 'sets the first name and last name' do
        expect {
          new_user = described_class.call(
            external_id: 'some-platform/12345', email: 'anunusedemail@example.com',
            first_name: 'Bob', last_name: 'Smith', role: 'student'
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
          role: 'student', is_test: is_test
        ).outputs.user
        expect(new_user.is_test).to eq is_test
        expect(new_user.reload.is_test).to eq is_test
      end

      it "finds the existing user by verified email instead of creating a duplicate" do
        existing_user = FactoryBot.create :user
        AddEmailToUser.call('verified@example.com', existing_user, already_verified: true)

        found = described_class.call(
          external_id: 'some-platform/12345',
          email: 'verified@example.com', already_verified: true
        ).outputs.user
        expect(found).to eq(existing_user)
      end

      it "attaches a non-conflicting email as before" do
        new_user = described_class.call(
          external_id: 'some-platform/11111', email: 'brandnew@example.com',
          first_name: 'Bob', last_name: 'Smith', already_verified: false, role: 'student'
        ).outputs.user
        expect(new_user.contact_infos.first.value).to eq('brandnew@example.com')
      end

    end

    context "given an email already claimed (unverified) by a different user" do
      let!(:other_user) { FactoryBot.create :user }
      let(:conflicting_email) { 'shared@example.com' }

      before { AddEmailToUser.call(conflicting_email, other_user, already_verified: false) }

      it "still creates the new user, without erroring, but does not attach the email" do
        result = nil
        expect {
          result = described_class.call(
            external_id: 'some-platform/99999', email: conflicting_email,
            first_name: 'Bob', last_name: 'Smith', already_verified: false, role: 'student'
          )
        }.to change(User, :count).by(1)

        expect(result.errors).to be_empty
        new_user = result.outputs.user
        expect(new_user).not_to eq(other_user)
        expect(new_user.contact_infos).to be_empty
        expect(new_user.external_ids.first.external_id).to eq('some-platform/99999')
      end

      it "leaves the other (unverified) user's email untouched" do
        described_class.call(
          external_id: 'some-platform/99998', email: conflicting_email,
          first_name: 'Bob', last_name: 'Smith', already_verified: false, role: 'student'
        )
        expect(other_user.reload.contact_infos.first.value).to eq(conflicting_email)
      end
    end

    context "given a verified email matching an unclaimed user with an unverified email" do
      let!(:unclaimed_user) { FactoryBot.create :user, state: 'unclaimed' }
      let(:shared_email) { 'placeholder@example.com' }

      before do
        AddEmailToUser.call(shared_email, unclaimed_user, already_verified: false)

        group = FactoryBot.create(:group)
        group.add_member unclaimed_user
        group.add_owner unclaimed_user
      end

      it "claims it: creates a new user, transfers associations, and destroys the old one" do
        result = nil
        expect {
          result = described_class.call(
            external_id: 'some-platform/claim-1', email: shared_email,
            first_name: 'Bob', last_name: 'Smith', already_verified: true, role: 'student'
          )
        }.to change(User, :count).by(0) # one created, one destroyed

        new_user = result.outputs.user
        expect(new_user).not_to eq(unclaimed_user)
        expect(new_user.contact_infos.first.value).to eq(shared_email)
        expect(new_user.contact_infos.first.verified).to be_truthy
        expect(new_user.external_ids.first.external_id).to eq('some-platform/claim-1')

        expect { unclaimed_user.reload }.to raise_error(ActiveRecord::RecordNotFound)

        expect(new_user.reload.owned_groups.count).to eq(1)
        expect(new_user.reload.member_groups.count).to eq(1)
      end
    end

    context "given a verified email matching an activated user's unverified secondary contact" do
      let!(:activated_user) { FactoryBot.create :user_with_emails, emails_count: 1 }
      let(:stray_email) { activated_user.contact_infos.first.value }

      it "leaves that account untouched, and creates a fresh account with the email instead" do
        result = nil
        expect {
          result = described_class.call(
            external_id: 'some-platform/claim-2', email: stray_email,
            first_name: 'Bob', last_name: 'Smith', already_verified: true, role: 'student'
          )
        }.to change(User, :count).by(1)

        new_user = result.outputs.user
        expect(new_user).not_to eq(activated_user)
        expect(new_user.contact_infos.first.value).to eq(stray_email)
        expect(new_user.contact_infos.first.verified).to be_truthy

        expect { activated_user.reload }.not_to raise_error
        expect(activated_user.contact_infos).to be_empty
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
