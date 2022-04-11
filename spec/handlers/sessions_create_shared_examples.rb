require 'rails_helper'

RSpec.shared_examples 'sessions create shared examples' do
  let(:user_state) { MockUserState.new }
  let(:login_providers) { nil }

  context "logging in" do
    context "no user linked to oauth response" do
      let(:login_providers) { { does_not: {uid: 'matter'} } }

      it "returns mismatched_authentication status and does not log in" do
        result = nil
        expect do
          # fabricated so no user will be linked
          result = handle request: MockOmniauthRequest.new('facebook', 'blah', {})
        end.not_to change { user_state.signed_in? }
        expect(result.outputs.status).to eq :mismatched_authentication
      end
    end

    # context "oauth response doesn't match log in username/email" do
    #   let(:authentication) { FactoryBot.create(:authentication, provider: 'google_oauth2') }
    #   let(:login_providers) { { google_oauth2: { uid: 'some_other_uid'} } }
    #
    #   it "returns mismatched_authentication status and does not log in" do
    #     result = nil
    #     expect do
    #       result = handle(
    #         request: MockOmniauthRequest.new(authentication.provider, authentication.uid, {})
    #       )
    #     end.not_to change { user_state.signed_in? }
    #     expect(result.outputs.status).to eq :mismatched_authentication
    #   end
    # end

    context "happy path" do
      let(:authentication) { FactoryBot.create(:authentication, provider: 'google_oauth2') }
      let(:login_providers) { { google_oauth2: { uid: authentication.uid } } }

      it "returns returning_user status and logs in" do
        result = handle(
          request: MockOmniauthRequest.new(authentication.provider, authentication.uid, {})
        )
        expect(result.outputs.status).to eq :returning_user
        expect(user_state).to be_signed_in
      end

      it "as a side effect updates the login_hint for google oauth" do
        result = handle(
          request: MockOmniauthRequest.new(authentication.provider,
                                           authentication.uid,
                                           {email: "bob@bob.com"})
        )
        expect(result.outputs.authentication.login_hint).to eq "bob@bob.com"
      end
    end
  end

  context "signing up" do
    # context "oauth response already directly linked to a user" do
    #   let(:authentication) { FactoryBot.create(:authentication, provider: 'google_oauth2') }
    #
    #   it "returns existing_user_signed_up_again status and transfers email" do
    #     result = handle(
    #       request: MockOmniauthRequest.new(authentication.provider, authentication.uid, {})
    #     )
    #     expect(result.outputs.status).to eq :existing_user_signed_up_again
    #     expect(authentication.user.contact_infos.verified.map(&:value)).to include "bob@bob.com"
    #   end
    # end

    context "oauth response already linked to user by email address" do
      let(:other_user_email) { FactoryBot.create(:email_address, verified: true)}

      it "returns existing_user_signed_up_again status and transfers auth" do
        expect do
          result = handle(request: MockOmniauthRequest.new("facebook",
                                                           "some_uid",
                                                           {email: other_user_email.value}))
          expect(result.outputs.status).to eq :existing_user_signed_up_again
        end.to change{other_user_email.user.reload.authentications.count}.by 1
      end
    end

    context "normal password sign up" do
      let(:identity) { FactoryBot.create :identity }

      it "adds authentication, logs in user, returns new_password_user" do
        expect(identity.user.authentications).to be_empty
        result = handle(request: MockOmniauthRequest.new("identity", identity.uid, {}))
        expect(result.outputs.status).to eq :new_password_user
        user = identity.user
        expect(user.authentications).not_to be_empty
        expect(user_state).to be_signed_in
        expect(user.contact_infos.size).to eq 1
        expect(user.contact_infos.first.value).to eq "bob@bob.com"
        expect(user.contact_infos.first).to be_verified
      end
    end

    context "normal social sign up" do

      it "adds authentication, logs in user, returns new_social_user" do
        result = handle(request: MockOmniauthRequest.new("facebook", "zuckerberg", {}))
        expect(result.outputs.status).to eq :new_social_user
        expect(user_state).to be_signed_in
        user = user_state.current_user
        authentication = user.authentications.reload.first
        expect(authentication.provider).to eq "facebook"
        expect(authentication.uid).to eq "zuckerberg"
        expect(user.contact_infos.size).to eq 1
        expect(user.contact_infos.first.value).to eq "bob@bob.com"
        expect(user.contact_infos.first).to be_verified
      end
    end
  end

  def handle(**args)
    described_class.handle(user_state: user_state,
                           login_providers: login_providers,
                           **args)
  end

end
