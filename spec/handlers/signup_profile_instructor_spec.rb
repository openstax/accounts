require 'rails_helper'

# TODO implement this -- what is below is just a sketch, hasn't been run ever

RSpec.describe SignupProfileInstructor, type: :handler do

  xcontext "when the user has arrived well-formed" do

    let(:user) {
      # user in good state
    }

    context "when the fields are missing" do
      let (:the_call) { -> {
        described_class.handle(
          params: {
            signup: {
              username: 'joebob',
              first_name: 'joe',
              last_name: 'bob',
              password: 'pass',
              password_confirmation: 'word',
              email_address: 'joebob@example.com'
            }
          },
          caller: user
        )
      }}

      it "has errors" do
        outcome = the_call.call
        expect(outcome.errors).to have_offending_input(:signup)
        expect(outcome.errors).to have_offending_input(:password)
      end

      # TODO other specs

    end

    context "when the fields are properly filled in" do
      let (:the_call) { -> {
        described_class.handle(
          params: {
            signup: {
              # include agreement? can't submit without
            }
          },
          caller: user
        )
      }}

      xit "has no errors" do
        outcome = the_call.call
        expect(outcome.errors).to be_empty
      end

      xit "updates the user's info" do
        # check school too
      end

      xit "sends a Lead off to Salesforce" do
      end

      xit "agrees to terms for the user" do
      end

      xit "leaves the user in the 'activated' state" do
      end
    end

  end


end
