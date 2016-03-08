require 'spec_helper'

describe IdentitiesRegister do

  context "when user info ok but passwords don't match" do
    let (:identities_register_call) { -> {
      IdentitiesRegister.handle(
        params: {
          register: {
            username: 'joebob',
            first_name: 'joe',
            last_name: 'bob',
            password: 'pass',
            password_confirmation: 'word',
            email: 'joebob@example.com'
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
      expect(IdentitiesRegister.handle(
        params: {
          register: {
            username: 'joebob',
            first_name: 'joe',
            last_name: 'bob',
            password: 'password',
            password_confirmation: 'password',
            email: 'joebob@example.com'
          }
        },
        caller: AnonymousUser.instance
      ).errors).to be_empty
    end

    it "has errors for [:register, :username] if not logged in" do
      outcome = IdentitiesRegister.handle(
        params: {
          register: {
            username: 'joebob',
            first_name: 'joe',
            last_name: 'bob',
            password: 'password',
            password_confirmation: 'password',
            email: 'joebob@example.com'
          }
        },
        caller: AnonymousUser.instance
      )
      expect(outcome.errors).to have_offending_input(:register)
      expect(outcome.errors).to have_offending_input(:username)
    end

    it "has errors for [:register, :user_id] if logged in" do
      outcome = IdentitiesRegister.handle(
        params: {
          register: {
            username: 'joebob',
            first_name: 'joe',
            last_name: 'bob',
            password: 'password',
            password_confirmation: 'password',
            email: 'joebob@example.com'
          }
        },
        caller: User.find_by_username('joebob')
      )
      expect(outcome.errors.map(&:code)).to eq [:already_has_identity]
    end
  end

end
