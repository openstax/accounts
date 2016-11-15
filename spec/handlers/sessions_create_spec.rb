# coding: utf-8
require 'rails_helper'

describe SessionsCreate, type: :handler do

  let(:user_state) { MockUserState.new }

  context "not previously signed in" do
    context "new authorization" do
      context "with no email or with an email not in the database" do
        context "using a password" do
          # Identity already exists (was created during the OAuth request phase)
          let!(:identity)       { FactoryGirl.create(:identity) }

          it "makes a new user with password" do
            result = described_class.handle(
              user_state: user_state,
              request: MockOmniauthRequest.new('identity', identity.uid, {})
            )

            expect(result.outputs[:status]).to eq :new_password_user

            expect(user_state.current_user).not_to be_nil
            expect(user_state.current_user.is_activated?).to eq false

            linked_authentications = user_state.current_user.authentications
            expect(linked_authentications.size).to eq 1
            expect(linked_authentications.first.provider).to eq 'identity'
            expect(linked_authentications.first.uid).to eq identity.uid
          end
        end

        xcontext "using a social network" do
          let!(:authentication) { FactoryGirl.create(:authentication,
                                                     user: nil,
                                                     provider: 'twitter') }

          it "makes a new social user" do
            result = described_class.handle(
              user_state: user_state,
              request: MockOmniauthRequest.new(authentication.provider, authentication.uid, {name: 'User One'})
            )

            expect(result.outputs[:status]).to eq(:new_social_user)

            linked_authentications = user_state.current_user.authentications
            expect(linked_authentications.size).to eq 1
            expect(linked_authentications.first.provider).to eq 'twitter'
            expect(linked_authentications.first.uid).to eq authentication.uid
          end

          it "gracefully handles making a new social user with non-western characters" do
            result = described_class.handle(
              user_state: user_state,
              request: MockOmniauthRequest.new(authentication.provider,
                                               authentication.uid,
                                               {nickname: "將", name: 'あき お'})
            )

            expect(result.errors).to be_empty
            expect(User.last.username).to match(%r/\Auser\d+\z/)
          end
        end
      end

      context "with an email that matches existing emails" do
        context "for one user" do
          let!(:authentication) { FactoryGirl.create(:authentication,
                                                     user: nil,
                                                     provider: 'facebook') }
          let!(:user)           { FactoryGirl.create(:user_with_emails, emails_count: 2) }

          before(:each) do
            ci = user.contact_infos.first
            ci.verified = true
            ci.save!
          end

          it "should link new auth to the existing user" do
            result = nil
            expect{
              result = described_class.handle(
                user_state: user_state,
                request: MockOmniauthRequest.new(
                  authentication.provider,
                  authentication.uid,
                  { email: user.contact_infos.first.value }
                )
              )
            }.to change{user.authentications.count}.by 1
            expect(result.outputs[:status]).to eq :transferred_authentication
            expect(user_state.current_user).to eq user
          end
        end

        context "for many users" do
          let!(:authentication) { FactoryGirl.create(:authentication,
                                                     user: nil,
                                                     provider: 'facebook') }
          let!(:user1)  { FactoryGirl.create(:user) }
          let!(:user2)  { FactoryGirl.create(:user) }
          let!(:email1) { FactoryGirl.create(:email_address, user: user1) }
          let!(:email2) { FactoryGirl.create(:email_address, value: email1.value, user: user2) }

          xit "ignores the other users and makes a new social user" do

            result = described_class.handle(
              user_state: user_state,
              request: MockOmniauthRequest.new(authentication.provider,
                                               authentication.uid,
                                               { email: email1.value, name: 'User One' })
            )

            expect(result.outputs[:status]).to eq(:new_social_user)

            linked_authentications = user_state.current_user.authentications
            expect(linked_authentications.size).to eq 1
            expect(linked_authentications.first.provider).to eq 'facebook'
            expect(linked_authentications.first.uid).to eq authentication.uid
          end
        end
      end
    end

    context "existing authorization" do
      let!(:authentication) { FactoryGirl.create(:authentication) }

      it "logs in the user and returns to app" do
        result = described_class.handle(
          user_state: user_state,
          request: MockOmniauthRequest.new(authentication.provider, authentication.uid, {})
        )

        expect(result.outputs[:status]).to eq :returning_user
        expect(user_state.current_user).to eq authentication.user
      end
    end
  end

  context "with a recent signin" do
    before(:each) do
      user_state.sign_in!(signed_in_user)
      SecurityLog.create! user: signed_in_user, remote_ip: '127.0.0.1',
                          event_type: :sign_in_successful, event_data: {}
    end

    context "as a temp user" do
      let(:signed_in_user)    { FactoryGirl.create(:temp_user) }
      let(:other_user)        { FactoryGirl.create(:user)}
      let(:other_temp_user)   { FactoryGirl.create(:temp_user) }

      context "new authorization" do
        let!(:authentication) { FactoryGirl.create(:authentication, user: nil) }

        context "with no email or with an email not in the database" do
          it "adds auth to the signed in user and prompt new or returning" do
            result = described_class.handle(
              user_state: user_state,
              request: MockOmniauthRequest.new(authentication.provider, authentication.uid, {})
            )

            expect(result.outputs[:status]).to eq :authentication_added
            expect(user_state.current_user).to eq signed_in_user
            expect(authentication.reload.user).to eq signed_in_user
          end
        end

        context "with new email" do
          it 'adds auth and email to the signed in user' do
            authentication.provider = 'facebook'
            authentication.save!
            signed_in_user.first_name = 'First'
            signed_in_user.last_name = 'Last'
            signed_in_user.save!

            result = described_class.handle(
              user_state: user_state,
              request: MockOmniauthRequest.new(authentication.provider,
                                               authentication.uid,
                                               { email: 'user@facebook.com',
                                                 first_name: 'User',
                                                 last_name: 'One' })
            )
            signed_in_user.reload

            expect(result.outputs[:status]).to eq(:authentication_added)
            expect(user_state.current_user).to eq(signed_in_user)
            expect(signed_in_user.first_name).to eq('First')
            expect(signed_in_user.last_name).to eq('Last')
            email = EmailAddress.find_by_value('user@facebook.com')
            expect(email.user).to eq(signed_in_user)
            expect(email.verified).to be true
          end
        end

        context 'that belongs to another user' do
          before :each do
            authentication.user = other_user
            authentication.save!
          end

          it 'does not add auth to the signed in user' do
            result = described_class.handle(
              user_state: user_state,
              request: MockOmniauthRequest.new(authentication.provider, authentication.uid, {})
            )

            expect(result.outputs[:status]).to eq(:authentication_taken)
            expect(user_state.current_user).to eq(signed_in_user)
            expect(authentication.reload.user).to eq(other_user)
            expect(signed_in_user.reload.authentications).to_not include(authentication)
          end
        end
      end

      context "existing authorization" do
        context "linked to self" do
          let!(:authentication) { FactoryGirl.create(:authentication,
                                                     provider: 'facebook',
                                                     user: signed_in_user) }

          it "maintains signed in user" do
            result = described_class.handle(
              user_state: user_state,
              request: MockOmniauthRequest.new(authentication.provider, authentication.uid, {})
            )

            expect(result.outputs[:status]).to eq :no_action
            expect(user_state.current_user).to eq signed_in_user
            expect(authentication.reload.user).to eq signed_in_user
          end
        end

        context "linked to another" do
          context "temp user" do
            let!(:other_temp_user)      { FactoryGirl.create(:temp_user) }
            let!(:authentication)       {
              FactoryGirl.create(:authentication, provider: 'twitter', user: other_temp_user)
            }
            let!(:other_authentication) {
              FactoryGirl.create(:authentication, provider: 'google', user: other_temp_user)
            }

            # weird edge case? not on flow chart
            it "transfers the auth to the signed in user, leave the other auths to other user" do
              result = described_class.handle(
                user_state: user_state,
                request: MockOmniauthRequest.new(authentication.provider, authentication.uid, {})
              )

              expect(result.outputs[:status]).to eq :authentication_added
              expect(user_state.current_user).to eq signed_in_user
              expect(authentication.reload.user).to eq signed_in_user
              expect(other_authentication.reload.user).to eq other_temp_user
            end
          end

          context "non-temp user" do
            let!(:other_user)           { FactoryGirl.create(:user) }
            let!(:authentication)       {
              FactoryGirl.create(:authentication, provider: 'twitter', user: other_user)
            }
            let!(:other_authentication) {
              FactoryGirl.create(:authentication, provider: 'google', user: other_user)
            }

            it "does not transfer auths to signed in user" do
              result = described_class.handle(
                user_state: user_state,
                request: MockOmniauthRequest.new(authentication.provider, authentication.uid, {})
              )

              expect(result.outputs[:status]).to eq :authentication_taken
              expect(user_state.current_user).to eq signed_in_user
              expect(authentication.reload.user).to eq other_user
              expect(other_authentication.reload.user).to eq other_user
              expect(signed_in_user.reload.authentications).to_not include(authentication)
            end
          end
        end
      end
    end

    context "as a non-temp user" do
      let(:signed_in_user)      { FactoryGirl.create(:user) }
      let(:other_user)          { FactoryGirl.create(:user)}
      let(:other_temp_user)     { FactoryGirl.create(:temp_user) }

      context "new authorization" do

        context "with no email or with an email not in the database" do
          let!(:authentication) { FactoryGirl.create(:authentication, user: nil) }

          it "adds the auth to the signed in user and returns to app" do
            auth_data = {provider: authentication.provider,
                         uid: authentication.uid}
            result = nil
            expect{
              result = described_class.handle(
                user_state: user_state,
                request: MockOmniauthRequest.new(authentication.provider, authentication.uid, {})
              )
            }.to change{signed_in_user.authentications.count}.by 1
            expect(result.outputs[:status]).to eq :authentication_added
            expect(user_state.current_user).to eq signed_in_user
          end
        end
      end

      context "existing authorization" do
        context "linked to self" do
          let!(:authentication) { FactoryGirl.create(:authentication, user: signed_in_user) }

          it "maintains signed in user and returns to app" do
            result = described_class.handle(
              user_state: user_state,
              request: MockOmniauthRequest.new(authentication.provider, authentication.uid, {})
            )

            expect(result.outputs[:status]).to eq :no_action
            expect(user_state.current_user).to eq signed_in_user
          end
        end

        context "linked to another" do
          context "temp user" do
            let!(:other_temp_user) { FactoryGirl.create(:temp_user) }
            let!(:authentication)  {
              FactoryGirl.create(:authentication, user: other_temp_user)
            }

            it "transfers temp user auths to signed in user, destroys temp user, returns to app" do
              result = described_class.handle(
                user_state: user_state,
                request: MockOmniauthRequest.new(authentication.provider, authentication.uid, {})
              )
              expect(authentication.reload.user).to eq signed_in_user
              expect(result.outputs[:status]).to eq :authentication_added
              expect(User.exists?(other_temp_user.id)).to eq false
            end
          end

          context "non-temp user" do
            let!(:other_user)     { FactoryGirl.create(:user)}
            let!(:authentication) { FactoryGirl.create(:authentication, user: other_user) }

            it "does not add auth to signed in user" do
              result = described_class.handle(
                user_state: user_state,
                request: MockOmniauthRequest.new(authentication.provider, authentication.uid, {})
              )

              expect(result.outputs[:status]).to eq :authentication_taken
              expect(authentication.user).to eq other_user
              expect(user_state.current_user).to eq signed_in_user
              expect(signed_in_user.reload.authentications).to_not include(authentication)
            end
          end
        end

        context "linked to no one" do
          context "but user already has already authenticated with the same provider before" do
            context "new_social user" do
              let!(:signed_in_user) { FactoryGirl.create(:new_social_user) }
              let!(:authentication) { FactoryGirl.create(:authentication, user: signed_in_user) }

              it "returns a status output instead of an exception or errors" do
                skip # clean this up when re-evaluate all code in SessionsCreate
                handle_with_uid(111)

                same_provider_different_uid = nil
                expect{same_provider_different_uid = handle_with_uid(222)}.not_to raise_exception
                expect(same_provider_different_uid.outputs[:status]).to eq :same_provider
                expect(same_provider_different_uid.errors).to be_empty
              end
            end

            xcontext "temp user" do
              let!(:signed_in_user) { FactoryGirl.create(:temp_user) }
              let!(:authentication) { FactoryGirl.create(:authentication, user: signed_in_user) }

              it "returns a status output instead of an exception or errors" do
                handle_with_uid(111)

                same_provider_different_uid = nil
                expect{same_provider_different_uid = handle_with_uid(222)}.not_to raise_exception
                expect(same_provider_different_uid.outputs[:status]).to eq :same_provider
                expect(same_provider_different_uid.errors).to be_empty
              end
            end

            context "non-temp user" do
              let!(:signed_in_user) { FactoryGirl.create(:user) }
              let!(:authentication) { FactoryGirl.create(:authentication, user: signed_in_user) }

              it "returns a status output instead of an exception or errors" do
                handle_with_uid(111)

                same_provider_different_uid = nil
                expect{same_provider_different_uid = handle_with_uid(222)}.not_to raise_exception
                expect(same_provider_different_uid.outputs[:status]).to eq :same_provider
                expect(same_provider_different_uid.errors).to be_empty
              end
            end
          end

          def handle_with_uid(uid)
            described_class.handle(
                              user_state: user_state,
                              request: MockOmniauthRequest.new(authentication.provider, uid, {})
                            )
          end
        end
      end
    end
  end

  context "with an old signin" do
    before(:each) do
      user_state.sign_in!(signed_in_user)
      SecurityLog.create! user: signed_in_user, remote_ip: '127.0.0.1',
                          event_type: :sign_in_successful, event_data: {}
      Timecop.freeze(Time.now + RequireRecentSignin::REAUTHENTICATE_AFTER)
    end

    context "as a temp user" do
      let(:signed_in_user)    { FactoryGirl.create(:temp_user) }
      let(:other_user)        { FactoryGirl.create(:user)}
      let(:other_temp_user)   { FactoryGirl.create(:temp_user) }

      context "new authorization" do
        let!(:authentication) { FactoryGirl.create(:authentication, user: nil) }

        context "with no email or with an email not in the database" do
          it "fails due to old signin" do
            result = described_class.handle(
              user_state: user_state,
              request: MockOmniauthRequest.new(authentication.provider, authentication.uid, {})
            )

            expect(result.outputs[:status]).to eq :new_signin_required
            expect(user_state.current_user).to eq signed_in_user
            expect(authentication.reload.user).to be_nil
          end
        end

        context "with new email" do
          it 'fails due to old signin' do
            authentication.provider = 'facebook'
            authentication.save!
            signed_in_user.first_name = 'First'
            signed_in_user.last_name = 'Last'
            signed_in_user.save!

            result = described_class.handle(
              user_state: user_state,
              request: MockOmniauthRequest.new(authentication.provider,
                                               authentication.uid,
                                               { email: 'user@facebook.com',
                                                 first_name: 'User',
                                                 last_name: 'One' })
            )
            signed_in_user.reload

            expect(result.outputs[:status]).to eq(:new_signin_required)
            expect(user_state.current_user).to eq(signed_in_user)
            expect(signed_in_user.first_name).to eq('First')
            expect(signed_in_user.last_name).to eq('Last')
            email = EmailAddress.find_by_value('user@facebook.com')
            expect(email).to be_nil
          end
        end

        context 'that belongs to another user' do
          before :each do
            authentication.user = other_user
            authentication.save!
          end

          it 'does not add auth to the signed in user' do
            result = described_class.handle(
              user_state: user_state,
              request: MockOmniauthRequest.new(authentication.provider, authentication.uid, {})
            )

            expect(result.outputs[:status]).to eq(:authentication_taken)
            expect(user_state.current_user).to eq(signed_in_user)
            expect(authentication.reload.user).to eq(other_user)
            expect(signed_in_user.reload.authentications).to_not include(authentication)
          end
        end
      end

      context "existing authorization" do
        context "linked to self" do
          let!(:authentication) { FactoryGirl.create(:authentication,
                                                     provider: 'facebook',
                                                     user: signed_in_user) }

          it "maintains signed in user" do
            result = described_class.handle(
              user_state: user_state,
              request: MockOmniauthRequest.new(authentication.provider, authentication.uid, {})
            )

            expect(result.outputs[:status]).to eq :no_action
            expect(user_state.current_user).to eq signed_in_user
            expect(authentication.reload.user).to eq signed_in_user
          end
        end

        context "linked to another" do
          context "temp user" do
            let!(:other_temp_user)      { FactoryGirl.create(:temp_user) }
            let!(:authentication)       {
              FactoryGirl.create(:authentication, provider: 'twitter', user: other_temp_user)
            }
            let!(:other_authentication) {
              FactoryGirl.create(:authentication, provider: 'google', user: other_temp_user)
            }

            # weird edge case? not on flow chart
            it "fails due to old signin" do
              result = described_class.handle(
                user_state: user_state,
                request: MockOmniauthRequest.new(authentication.provider, authentication.uid, {})
              )

              expect(result.outputs[:status]).to eq :new_signin_required
              expect(user_state.current_user).to eq signed_in_user
              expect(authentication.reload.user).to eq other_temp_user
              expect(other_authentication.reload.user).to eq other_temp_user
            end
          end

          context "non-temp user" do
            let!(:other_user)           { FactoryGirl.create(:user) }
            let!(:authentication)       {
              FactoryGirl.create(:authentication, provider: 'twitter', user: other_user)
            }
            let!(:other_authentication) {
              FactoryGirl.create(:authentication, provider: 'google', user: other_user)
            }

            it "does not transfer auths to signed in user" do
              result = described_class.handle(
                user_state: user_state,
                request: MockOmniauthRequest.new(authentication.provider, authentication.uid, {})
              )

              expect(result.outputs[:status]).to eq :authentication_taken
              expect(user_state.current_user).to eq signed_in_user
              expect(authentication.reload.user).to eq other_user
              expect(other_authentication.reload.user).to eq other_user
              expect(signed_in_user.reload.authentications).to_not include(authentication)
            end
          end
        end
      end
    end

    context "as a non-temp user" do
      let(:signed_in_user)  { FactoryGirl.create(:user) }
      let(:other_user)      { FactoryGirl.create(:user)}
      let(:other_temp_user) { FactoryGirl.create(:temp_user) }

      context "new authorization" do

        context "with no email or with an email not in the database" do
          let!(:authentication) {
            FactoryGirl.create(:authentication, user: nil)
          }

          it "fails due to old signin" do
            auth_data = {provider: authentication.provider, uid: authentication.uid}
            result = nil
            expect{
              result = described_class.handle(
                user_state: user_state,
                request: MockOmniauthRequest.new(authentication.provider, authentication.uid, {})
              )
            }.not_to change{signed_in_user.authentications.count}
            expect(result.outputs[:status]).to eq :new_signin_required
            expect(user_state.current_user).to eq signed_in_user
          end
        end
      end

      context "existing authorization" do
        context "linked to self" do
          let!(:authentication) { FactoryGirl.create(:authentication, user: signed_in_user) }

          it "maintains signed in user and returns to app" do
            result = described_class.handle(
              user_state: user_state,
              request: MockOmniauthRequest.new(authentication.provider, authentication.uid, {})
            )

            expect(result.outputs[:status]).to eq :no_action
            expect(user_state.current_user).to eq signed_in_user
          end
        end

        context "linked to another" do
          context "temp user" do
            let!(:other_temp_user) { FactoryGirl.create(:temp_user) }
            let!(:authentication)  { FactoryGirl.create(:authentication, user: other_temp_user) }

            it "fails due to old signin" do
              result = described_class.handle(
                user_state: user_state,
                request: MockOmniauthRequest.new(authentication.provider, authentication.uid, {})
              )
              expect(authentication.reload.user).to eq other_temp_user
              expect(result.outputs[:status]).to eq :new_signin_required
              expect(User.exists?(other_temp_user.id)).to eq true
            end
          end

          context "non-temp user" do
            let!(:other_user)     { FactoryGirl.create(:user)}
            let!(:authentication) { FactoryGirl.create(:authentication, user: other_user) }

            it "does not add auth to signed in user" do
              result = described_class.handle(
                user_state: user_state,
                request: MockOmniauthRequest.new(authentication.provider, authentication.uid, {})
              )

              expect(result.outputs[:status]).to eq :authentication_taken
              expect(authentication.user).to eq other_user
              expect(user_state.current_user).to eq signed_in_user
              expect(signed_in_user.reload.authentications).to_not include(authentication)
            end
          end
        end
      end
    end
  end

end
