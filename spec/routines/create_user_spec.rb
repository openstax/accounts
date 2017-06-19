require 'rails_helper'

describe CreateUser do

  context "when all validations pass" do
    context "when ensure_no_errors is false" do
      it "creates a new user" do
        expect{
          CreateUser.call(username: "unclebob", first_name: "Robert", last_name: "Martin", ensure_no_errors: false, state: "activated")
        }.to change{User.count}.by 1
      end
    end

    context "when ensure_no_errors is true" do
      it "creates a new user" do
        expect{
          CreateUser.call(username: "unclebob", first_name: "Robert", last_name: "Martin", ensure_no_errors: true, state: "activated")
        }.to change{User.count}.by 1
      end

      it 'sets a specified role' do
        expect(CreateUser[role: :instructor, ensure_no_errors: true, state: "activated"].role).to eq 'instructor'
      end
    end
  end

  context "when validations fail" do
    shared_examples "with invalid user state" do
      it "raises an exception" do
        expect{
          CreateUser.call(username: "unclebob", first_name: "Robert", last_name: "Martin", ensure_no_errors: true, state: "bogus_state!")
        }.to raise_error(StandardError)
      end
    end

    context "when ensure_no_errors is false" do
      it_behaves_like "with invalid user state"

      context "with invalid user information" do
        it "returns errors" do
          invalid_input = CreateUser.call(username: "!@#$%^&*", first_name: "!@#$%^&*", last_name: "!@#$%^&*", ensure_no_errors: false, state: 'activated')
          expect(invalid_input.errors).to_not be_empty
        end

        it "does not raise an exception" do
          expect{
            CreateUser.call(username: "!@#$%^&*", first_name: "!@#$%^&*", last_name: "!@#$%^&*", ensure_no_errors: false, state: 'activated')
          }.to_not raise_error
        end
      end

      context "when username is already taken" do
        it "fails with an error" do
          FactoryGirl.create(:user, username: "bubba")
          outcome = nil
          expect {
            outcome = CreateUser.call(username: "bubba",
                                      first_name: Faker::Name.first_name, last_name: Faker::Name.last_name,
                                      ensure_no_errors: false, state: 'activated')
          }.to change{User.count}.by 0
          expect(outcome.errors.has_offending_input?(:username)).to be_truthy
        end
      end
    end

    context "when ensure_no_errors is true" do
      it_behaves_like "with invalid user state"

      context "with invalid user information" do
        it "returns no errors" do
          invalid_input = CreateUser.call(username: "!@#$%^&*", first_name: "!@#$%^&*", last_name: "!@#$%^&*", ensure_no_errors: true, state: 'activated')
          expect(invalid_input.errors).to be_empty
        end

        it "does not raise an exception" do
          expect{
            CreateUser.call(username: "!@#$%^&*", first_name: "!@#$%^&*", last_name: "!@#$%^&*", ensure_no_errors: true, state: 'activated')
          }.to_not raise_error
        end
      end

      context "when username is already taken" do
        it "creates a new user" do
          FactoryGirl.create(:user, username: "bubba")
          expect { CreateUser.call(username: "bubba",
                                   first_name: Faker::Name.first_name, last_name: Faker::Name.last_name,
                                   ensure_no_errors: true, state: 'activated')
          }.to change{ User.count }.by 1
        end

        it "assigns a unique username" do
          FactoryGirl.create(:user, username: "bubba")
          outcome = CreateUser.call(username: "bubba",
                                    first_name: Faker::Name.first_name, last_name: Faker::Name.last_name,
                                    ensure_no_errors: true, state: 'activated')
          expect(outcome.outputs.user.username).to_not eq "bubba"
        end

        it "returns no errors" do
          FactoryGirl.create(:user, username: "bubba")
          outcome = CreateUser.call(username: "bubba",
                                    first_name: Faker::Name.first_name, last_name: Faker::Name.last_name,
                                    ensure_no_errors: true, state: 'activated')
          expect(outcome.errors).to be_empty
        end
      end

      context "when sanitized downcased username is already taken" do
        it "still creates a new user" do
          FactoryGirl.create(:user, username: "Userone")
          expect { CreateUser.call(username: "User One",
                                   first_name: Faker::Name.first_name, last_name: Faker::Name.last_name,
                                   ensure_no_errors: true, state: 'activated')
          }.to change{User.count}.by 1
        end

        it "assigns a unique username" do
          FactoryGirl.create(:user, username: "bubba")
          outcome = CreateUser.call(username: "bubba",
                                    first_name: Faker::Name.first_name, last_name: Faker::Name.last_name,
                                    ensure_no_errors: true, state: 'activated')
          expect(outcome.outputs.user.username).to_not eq "bubba"
        end

        it "returns no errors" do
          FactoryGirl.create(:user, username: "Usertwo")
          user_two = CreateUser.call(username: "User Two",
                                     first_name: Faker::Name.first_name, last_name: Faker::Name.last_name,
                                     ensure_no_errors: true, state: 'activated')
          expect(user_two.errors).to be_empty
        end
      end
    end
  end
end
