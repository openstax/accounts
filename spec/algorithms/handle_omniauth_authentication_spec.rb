require 'spec_helper'

describe HandleOmniauthAuthentication do
  
  let(:user_state) { MockUserState.new }

  context "when not signed in and no existing auth" do
    it "makes new user and prompts new or returning" do

      auth_data = {provider: 'dummy', provider_uid: 1, emails: []}
      next_action = HandleOmniauthAuthentication.call(auth_data, user_state)
      expect(next_action).to eq(:ask_new_or_returning)

      expect(user_state.current_user).not_to be_nil
      expect(user_state.current_user.person).to be_nil
      
      linked_authentications = user_state.current_user.authentications
      expect(linked_authentications.size).to eq 1
      expect(linked_authentications.first.provider).to eq 'dummy'
      expect(linked_authentications.first.uid).to eq "1"
    
    end
  end

  context "when not signed in auth exists" do
    it "logs in the user and returns to app" do
      authentication = FactoryGirl.create(:authentication_with_user)
      auth_data = {provider: authentication.provider, provider_uid: authentication.uid}

      next_action = HandleOmniauthAuthentication.call(auth_data, user_state)
      
      expect(next_action).to eq(:return_to_app)
      expect(user_state.current_user).to eq authentication.user
    end
  end

  context "when signed in as non temp user" do
    let(:signed_in_user) { FactoryGirl.create(:user_with_person) }
    let(:other_user) { FactoryGirl.create(:user_with_person)}
    let(:other_temp_user) { FactoryGirl.create(:user) }

    before { user_state.sign_in(signed_in_user) }

    context "when auth linked to signed in user" do
      let(:authentication) { FactoryGirl.create(:authentication, user: signed_in_user) }
      it "maintains signed in user and returns to app" do
        auth_data = {provider: authentication.provider, provider_uid: authentication.uid}
        next_action = HandleOmniauthAuthentication.call(auth_data, user_state)
        expect(next_action).to eq(:return_to_app)
        expect(user_state.current_user).to eq signed_in_user
      end
    end

    context "when auth not linked to a user" do
      let(:authentication) { FactoryGirl.create(:authentication) }
      it "adds the auth to the signed in user and returns to app" do
        auth_data = {provider: authentication.provider, provider_uid: authentication.uid}
        next_action = nil
        expect{
          next_action = HandleOmniauthAuthentication.call(auth_data, user_state)
        }.to change{signed_in_user.authentications.count}.by 1
        expect(next_action).to eq(:return_to_app)
        expect(user_state.current_user).to eq signed_in_user
      end
    end

    context "when auth linked to a temp user other than that signed in" do
      let(:other_temp_user) { FactoryGirl.create(:user) }
      let(:authentication) { FactoryGirl.create(:authentication, user: other_temp_user) }
      let(:auth_data) {{provider: authentication.provider, provider_uid: authentication.uid}}

      it "transfers temp user auths to signed in user, destroys temp user, returns to app" do
        next_action = HandleOmniauthAuthentication.call(auth_data, user_state)
        expect(authentication.reload.user).to eq signed_in_user
        expect(next_action).to eq :return_to_app
        expect(User.exists?(other_temp_user.id)).to be_false
      end
    end

    context "when auth linked to a non temp user other than that signed in" do
      let(:other_user) { FactoryGirl.create(:user_with_person)}
      let(:authentication) { FactoryGirl.create(:authentication, user: other_user) }

      it "leaves signed in user alone and asks which account to use" do
        auth_data = {provider: authentication.provider, provider_uid: authentication.uid}
        next_action = HandleOmniauthAuthentication.call(auth_data, user_state)
        expect(next_action).to eq :ask_which_account
        expect(authentication.user).to eq other_user
        expect(user_state.current_user).to eq signed_in_user
      end
    end

  end

  context "when signed in as temp user" do
    let(:signed_in_user) { FactoryGirl.create(:user) }
    let(:other_user) { FactoryGirl.create(:user_with_person)}
    let(:other_temp_user) { FactoryGirl.create(:user) }

    before { user_state.sign_in(signed_in_user) }

    # Readding an existing auth to a temp user
    context "when auth linked to signed in user" do
      let(:authentication) { FactoryGirl.create(:authentication, user: signed_in_user) }
      let(:auth_data) {{provider: authentication.provider, provider_uid: authentication.uid}}

      it "should maintain signed in user and prompt new or returning" do
        next_action = HandleOmniauthAuthentication.call(auth_data, user_state)
        expect(next_action).to eq :ask_new_or_returning
        expect(user_state.current_user).to eq signed_in_user
        expect(authentication.reload.user).to eq signed_in_user
      end
    end

    context "when auth not linked to a user" do
      let(:authentication) { FactoryGirl.create(:authentication) }
      let(:auth_data) {{provider: authentication.provider, provider_uid: authentication.uid}}

      it "should add auth to the signed in user and prompt new or returning" do
        next_action = HandleOmniauthAuthentication.call(auth_data, user_state)
        expect(next_action).to eq :ask_new_or_returning
        expect(user_state.current_user).to eq signed_in_user
        expect(authentication.reload.user).to eq signed_in_user
      end
    end

    context "when auth linked to a temp user other than that signed in" do
      let!(:other_temp_user) { FactoryGirl.create(:user) }
      let!(:authentication) { FactoryGirl.create(:authentication, user: other_temp_user) }
      let!(:other_authentication) { FactoryGirl.create(:authentication, user: other_temp_user) }
      let!(:auth_data) {{provider: authentication.provider, provider_uid: authentication.uid}}

      # weird edge case? not on flow chart
      it "transfers temp user auths to signed in user, destroys other temp user, prompts new or returning" do
        next_action = HandleOmniauthAuthentication.call(auth_data, user_state)
        expect(next_action).to eq :ask_new_or_returning
        expect(user_state.current_user).to eq signed_in_user
        expect(authentication.reload.user).to eq signed_in_user
        expect(other_authentication.reload.user).to eq signed_in_user
        expect(User.exists?(other_temp_user.id)).to be_false
      end
    end

    context "when auth linked to a non-temp user other than that signed in" do
      let!(:other_user) { FactoryGirl.create(:user_with_person) }
      let!(:authentication) { FactoryGirl.create(:authentication, user: other_user) }
      let!(:other_authentication) { FactoryGirl.create(:authentication, user: other_user) }
      let!(:auth_data) {{provider: authentication.provider, provider_uid: authentication.uid}}

      it "transfers auths to other user, destroys signed in user, signs in other user, returns to app" do
        next_action = HandleOmniauthAuthentication.call(auth_data, user_state)
        expect(next_action).to eq :return_to_app
        expect(user_state.current_user).to eq other_user
        expect(authentication.reload.user).to eq other_user
        expect(other_authentication.reload.user).to eq other_user
        expect(User.exists?(signed_in_user.id)).to be_false
      end
    end


  end



  # when new authentication email matches existing user

end