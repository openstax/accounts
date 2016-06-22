require 'rails_helper'

describe CreateUser do

  context "when ensure_no_errors is false" do

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
