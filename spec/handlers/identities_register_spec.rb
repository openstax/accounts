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
            password_confirmation: 'word'
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
      expect(outcome.errors.has_offending_input?([:register, :password]))
    end
  end

end
