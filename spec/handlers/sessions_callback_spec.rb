require 'spec_helper'

describe SessionsCallback do
  
  let(:user_state) { MockUserState.new }

  context "when not signed in and no existing auth" do
    it "makes new user and prompts new or returning" do
      # User is signing up
      # Identity and authentication already exist,
      # as they were created during the OAuth request phase
      # (this is the callback phase)
      identity = FactoryGirl.create(:identity)
      FactoryGirl.create(:authentication, user: identity.user,
                         uid: identity.id.to_s, provider: 'identity')

      result = SessionsCallback.handle(
        user_state: user_state,
        request: MockOmniauthRequest.new('identity', identity.user.id, [])
      )
      
      expect(result.outputs[:status]).to eq :new_user

      expect(user_state.current_user).not_to be_nil
      expect(user_state.current_user.person).to be_nil
      expect(user_state.current_user.is_temp).to be_true
      
      linked_authentications = user_state.current_user.authentications
      expect(linked_authentications.size).to eq 1
      expect(linked_authentications.first.provider).to eq 'identity'
      expect(linked_authentications.first.uid).to eq "1"

    end
  end

  context "when not signed in auth exists" do
    it "logs in the user and returns to app" do
      authentication = FactoryGirl.create(:authentication, user: FactoryGirl.create(:user))
      result = SessionsCallback.handle(
        user_state: user_state,
        request: MockOmniauthRequest.new(authentication.provider, authentication.uid, [])
      )
      
      expect(result.outputs[:status]).to eq :returning_user
      expect(user_state.current_user).to eq authentication.user
    end
  end

  context "when signed in as non temp user" do
    let(:signed_in_user) { FactoryGirl.create(:user) }
    let(:other_user) { FactoryGirl.create(:user)}
    let(:other_temp_user) { FactoryGirl.create(:temp_user) }

    before { user_state.sign_in(signed_in_user) }

    context "when auth linked to signed in user" do
      let(:authentication) { FactoryGirl.create(:authentication, user: signed_in_user) }

      it "maintains signed in user and returns to app" do
        result = SessionsCallback.handle(
          user_state: user_state,
          request: MockOmniauthRequest.new(authentication.provider, authentication.uid, [])
        )

        expect(result.outputs[:status]).to eq :returning_user
        expect(user_state.current_user).to eq signed_in_user
      end
    end

    context "when auth not linked to a user" do
      let(:authentication) { FactoryGirl.create(:authentication) }

      it "adds the auth to the signed in user and returns to app" do

        auth_data = {provider: authentication.provider, uid: authentication.uid}
        result = nil
        expect{
          result = SessionsCallback.handle(
            user_state: user_state,
            request: MockOmniauthRequest.new(authentication.provider, authentication.uid, [])
          )
        }.to change{signed_in_user.authentications.count}.by 1
        expect(result.outputs[:status]).to eq :returning_user
        expect(user_state.current_user).to eq signed_in_user
      end
    end

    context "when auth linked to a temp user other than that signed in" do
      let(:other_temp_user) { FactoryGirl.create(:temp_user) }
      let(:authentication) { FactoryGirl.create(:authentication, user: other_temp_user) }

      it "transfers temp user auths to signed in user, destroys temp user, returns to app" do
        result = SessionsCallback.handle(
          user_state: user_state,
          request: MockOmniauthRequest.new(authentication.provider, authentication.uid, [])
        )        
        expect(authentication.reload.user).to eq signed_in_user
        expect(result.outputs[:status]).to eq :returning_user
        expect(User.exists?(other_temp_user.id)).to be_false
      end
    end

    context "when auth linked to a non temp user other than that signed in" do
      let(:other_user) { FactoryGirl.create(:user)}
      let(:authentication) { FactoryGirl.create(:authentication, user: other_user) }

      it "leaves signed in user alone and asks which account to use" do
        result = SessionsCallback.handle(
          user_state: user_state,
          request: MockOmniauthRequest.new(authentication.provider, authentication.uid, [])
        )

        expect(result.outputs[:status]).to eq :multiple_accounts
        expect(authentication.user).to eq other_user
        expect(user_state.current_user).to eq signed_in_user
      end
    end

  end

  context "when signed in as temp user" do
    let(:signed_in_user) { FactoryGirl.create(:temp_user) }
    let(:other_user) { FactoryGirl.create(:user)}
    let(:other_temp_user) { FactoryGirl.create(:temp_user) }

    before { user_state.sign_in(signed_in_user) }

    # Readding an existing auth to a temp user
    context "when auth linked to signed in user" do
      let(:authentication) { FactoryGirl.create(:authentication, user: signed_in_user) }

      it "should maintain signed in user and prompt new or returning" do
        result = SessionsCallback.handle(
          user_state: user_state,
          request: MockOmniauthRequest.new(authentication.provider, authentication.uid, [])
        )

        expect(result.outputs[:status]).to eq :new_user
        expect(user_state.current_user).to eq signed_in_user
        expect(authentication.reload.user).to eq signed_in_user
      end
    end

    context "when auth not linked to a user" do
      let(:authentication) { FactoryGirl.create(:authentication) }

      it "should add auth to the signed in user and prompt new or returning" do
        result = SessionsCallback.handle(
          user_state: user_state,
          request: MockOmniauthRequest.new(authentication.provider, authentication.uid, [])
        )

        expect(result.outputs[:status]).to eq :new_user
        expect(user_state.current_user).to eq signed_in_user
        expect(authentication.reload.user).to eq signed_in_user
      end
    end

    context "when auth linked to a temp user other than that signed in" do
      let!(:other_temp_user) { FactoryGirl.create(:temp_user) }
      let!(:authentication) { FactoryGirl.create(:authentication, user: other_temp_user) }
      let!(:other_authentication) { FactoryGirl.create(:authentication, user: other_temp_user) }

      # weird edge case? not on flow chart
      it "transfers temp user auths to signed in user, destroys other temp user, prompts new or returning" do
        result = SessionsCallback.handle(
          user_state: user_state,
          request: MockOmniauthRequest.new(authentication.provider, authentication.uid, [])
        )
        
        expect(result.outputs[:status]).to eq :new_user
        expect(user_state.current_user).to eq signed_in_user
        expect(authentication.reload.user).to eq signed_in_user
        expect(other_authentication.reload.user).to eq signed_in_user
        expect(User.exists?(other_temp_user.id)).to be_false
      end
    end

    context "when auth linked to a non-temp user other than that signed in" do
      let!(:other_user) { FactoryGirl.create(:user) }
      let!(:authentication) { FactoryGirl.create(:authentication, user: other_user) }
      let!(:other_authentication) { FactoryGirl.create(:authentication, user: other_user) }

      it "transfers auths to other user, destroys signed in user, signs in other user, returns to app" do
        result = SessionsCallback.handle(
          user_state: user_state,
          request: MockOmniauthRequest.new(authentication.provider, authentication.uid, [])
        )

        expect(result.outputs[:status]).to eq :returning_user
        expect(user_state.current_user).to eq other_user
        expect(authentication.reload.user).to eq other_user
        expect(other_authentication.reload.user).to eq other_user
        expect(User.exists?(signed_in_user.id)).to be_false
      end
    end


  end

  context "when auth not linked to user but matches email of 1 user" do
    let!(:authentication) { FactoryGirl.create(:authentication) }
    let!(:user) { FactoryGirl.create(:user_with_emails, emails_count: 2) }
    let!(:auth_data) {{provider: authentication.provider, 
                       uid: authentication.uid,
                       emails: [user.contact_infos.first.value, "blah@blah.com"]}}

    it "should link that auth to that user" do
      result = SessionsCallback.handle(
          user_state: user_state,
          request: MockOmniauthRequest.new(authentication.provider, authentication.uid, [
                                           user.contact_infos.first.value, "blah@blah.com"])
      )
      expect(authentication.reload.user).to eq user
    end
  end

  context "when auth not linked to user but matches emails of 2 users" do
    # pending("Not worrying about this case for a while")

    # let!(:authentication) { FactoryGirl.create(:authentication) }
    # let!(:user1) { FactoryGirl.create(:user_with_emails, emails_count: 1) }
    # let!(:user2) { FactoryGirl.create(:user_with_emails, emails_count: 1) }
    # let!(:auth_data) {{provider: authentication.provider, 
    #                    uid: authentication.uid,
    #                    emails: [user1.contact_infos.first.value, user2.contact_infos.first.value]}}

    # it "should do something reasonable" do
    # end
  end

  # when new authentication email matches existing user

end
