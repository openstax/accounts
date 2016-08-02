require 'rails_helper'

describe CreateUser do

  context "when all validations pass" do
    it "creates a new user" do
      expect{
        CreateUser.call(username: "unclebob", title: "Mr.", first_name: "Robert", last_name: "Martin", state: "activated")
      }.to change{User.count}.by 1
    end
  end

  context "when validations fail" do
    context "when ensure_no_errors is false" do
      it "returns errors on invalid input" do
        outcome = nil
        expect{
          outcome = CreateUser.call(username: "unclebob", first_name: "Bob", last_name: "Martin", ensure_no_errors: false, state: 'bogus_state!')
        }.to_not raise_error

        expect(outcome.errors).to_not be_empty
      end

      it "fails with an error when the username is taken" do
        FactoryGirl.create(:user, username: "bubba")
        outcome = nil
        expect {
          outcome = CreateUser.call(username: "bubba", ensure_no_errors: false, state: 'activated')
        }.to change{User.count}.by 0
        expect(outcome.errors.has_offending_input?(:username)).to be_truthy
      end

    end

    context "when ensure_no_errors is true" do
      let(:invalid_input) {
        last_name = "!@#$%^&*"
        CreateUser.call(username: "unclebob", first_name: "Bob", last_name: last_name, ensure_no_errors: true, state: 'activated')
      }

      it "returns no errors" do
        expect(invalid_input.errors).to be_empty
      end

      it "can raise an exception" do
        expect{
          CreateUser.call(username: "unclebob", first_name: "Bob", last_name: "Martin", ensure_no_errors: true, state: 'bogus_state!')
        }.to raise_error(StandardError)
      end

      context "username" do
        it "succeeds when a username is already taken" do
          FactoryGirl.create(:user, username: "bubba")
          outcome = nil
          expect {
            outcome = CreateUser.call(username: "bubba", ensure_no_errors: true, state: 'activated')
          }.to change{User.count}.by 1
          expect(outcome.errors).to be_empty
        end

        it "succeeds when the sanitized downcased username is already taken" do
          FactoryGirl.create(:user, username: "Userone")
          outcome = nil
          expect {
            outcome = CreateUser.call(username: "User One", ensure_no_errors: true, state: 'activated')
          }.to change{User.count}.by 1
          expect(outcome.errors).to be_empty
        end
      end
    end
  end
end
