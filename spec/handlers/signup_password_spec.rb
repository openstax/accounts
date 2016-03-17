require 'rails_helper'

# TODO add specs for missing, but required, params
# TODO add in UsersRegister specs -- oops maybe are none?  then add specs to test rest of SignupProcess

describe SignupPassword do

  context "when user info ok but passwords don't match" do
    let (:identities_register_call) { -> {
      described_class.handle(
        params: {
          register: {
            username: 'joebob',
            first_name: 'joe',
            last_name: 'bob',
            password: 'pass',
            password_confirmation: 'word',
            email_address: 'joebob@example.com'
          }
        },
        caller: AnonymousUser.instance,
      )
    }}

    it "doesn't create the user" do
      expect(identities_register_call).not_to change(User, :count)
    end

    it "doesn't create the identity" do
      expect(identities_register_call).not_to change(Identity, :count)
    end

    it "has errors for [:register, :password]" do
      outcome = identities_register_call.call
      expect(outcome.errors).to have_offending_input(:register)
      expect(outcome.errors).to have_offending_input(:password)
    end
  end

  context "when the user already has a password" do
    before(:each) do
      expect(described_class.handle(
        params: {
          register: {
            username: 'joebob',
            first_name: 'joe',
            last_name: 'bob',
            password: 'password',
            password_confirmation: 'password',
            email_address: 'joebob@example.com'
          }
        },
        caller: AnonymousUser.instance
      ).errors).to be_empty
    end

    it "has errors for [:register, :username] if not logged in" do
      outcome = described_class.handle(
        params: {
          register: {
            username: 'joebob',
            first_name: 'joe',
            last_name: 'bob',
            password: 'password',
            password_confirmation: 'password',
            email_address: 'joebob@example.com'
          }
        },
        caller: AnonymousUser.instance
      )
      expect(outcome.errors).to have_offending_input(:register)
      expect(outcome.errors).to have_offending_input(:username)
    end

    it "has errors for [:register, :user_id] if logged in" do
      expect {
        described_class.handle(
          params: {
            register: {
              username: 'joebob',
              first_name: 'joe',
              last_name: 'bob',
              password: 'password',
              password_confirmation: 'password',
              email_address: 'joebob@example.com'
            }
          },
          caller: User.find_by_username('joebob')
        )
      }.to raise_error(Lev::SecurityTransgression)
    end
  end

end
