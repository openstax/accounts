require 'rails_helper'

RSpec.describe SignupPassword, type: :handler do
  ## MV: This handler was replaced with the create_password handler and set_password routine.
  # context "when the passwords don't match" do
  #   let (:the_call) { -> {
  #     described_class.handle(
  #       params: {
  #         signup: {
  #           password: 'pass',
  #           password_confirmation: 'word',
  #         }
  #       },
  #       caller: AnonymousUser.instance
  #     )
  #   }.call }
  #
  #   it "doesn't create the user" do
  #     expect{the_call}.not_to change(User, :count)
  #   end
  #
  #   it "doesn't create the identity" do
  #     expect{the_call}.not_to change(Identity, :count)
  #   end
  #
  #   it "has errors for password fields" do
  #     outcome = the_call
  #     expect(outcome.errors).to have_offending_input(:password)
  #     expect(outcome.errors).to have_offending_input(:password_confirmation)
  #   end
  # end
  #
  # context "when the passwords do match" do
  #   let (:the_call) { -> {
  #     described_class.handle(
  #       params: {
  #         signup: {
  #           password: 'password',
  #           password_confirmation: 'password',
  #         }
  #       },
  #       caller: AnonymousUser.instance
  #     )
  #   }.call }
  #
  #   it "creates the user with an identity and moves the contact info" do
  #     outcome = nil
  #
  #     expect{
  #       outcome = the_call
  #     }.to change(User, :count)
  #
  #     expect(outcome.errors).to be_empty
  #
  #     user = outcome.outputs.user
  #
  #     expect(user.identity).to be_present
  #   end
  # end
  #
  # context "when the user is already logged in with a non-anonymous user" do
  #   it "freaks out" do
  #     user = create_user 'user'
  #
  #     expect{
  #       described_class.handle(params: {signup: {}}, caller: user)
  #     }.to raise_error(Lev::SecurityTransgression)
  #   end
  # end

end
