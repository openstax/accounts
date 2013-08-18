require 'spec_helper'

describe HandleOmniauthAuthentication do
  
  let(:user_state) { MockUserState.new }

  context "when brand new user" do
    it "makes new user and prompts new or returning" do

      auth_data = {provider: 'dummy', provider_uid: 1, emails: []}
      next_action = HandleOmniauthAuthentication.call(auth_data, user_state)
      expect(next_action).to eq(:ask_new_or_returning)

      expect(user_state.current_user).not_to be_nil
      expect(user_state.current_user.person).to be_nil
      
      linked_authentications = user_state.current_user.authentications
      expect(linked_authentications.size).to eq 1
      expect(linked_authentications.first.provider).to eq 'dummy'
      expect(linked_authentications.first.uid).to eq 1
    
    end
  end

end