require 'rails_helper'

module Newflow
  feature 'student login flow', js: true do
    before do
      load 'db/seeds.rb' # creates terms of use and privacy policy contracts
      create_newflow_user('user@openstax.org', 'password')
    end

    context 'happy path' do
      describe 'using SSO cookie' do
        it 'sends the student back to the specified return URL' do
          with_forgery_protection do
            return_to = capybara_url(external_app_for_specs_path)
            visit login_path(r: return_to)
            screenshot!
            log_in_user('user@openstax.org', 'password')
            expect(page.current_url).to eq(return_to)
            screenshot!
          end
        end
      end

      describe 'arriving from an OAuth app' do
        describe 'when student has signed the terms of use' do
          it 'sends the student back to the app' do
            with_forgery_protection do
              arrive_from_app
              screenshot!
              log_in_user('user@openstax.org', 'password')
              expect_back_at_app
              screenshot!
            end
          end
        end

        describe 'when student has NOT signed the terms of use' do
          let(:user) do
            create_newflow_user('needs_profile_user@openstax.org', 'password', false)
          end

          before do
            user.update(state: User::NEEDS_PROFILE)
          end

          it 'requires the student to fill out their profile (and thus sign the terms of use)' do
            with_forgery_protection do
              arrive_from_app
              screenshot!
              log_in_user('needs_profile_user@openstax.org', 'password')
              screenshot!
              expect(page.current_path).to match('/terms/pose')
            end
          end
        end
      end

      describe 'with no return parameter specified, when feature flag is on' do
        it 'sends the student to their profile' do
          with_forgery_protection do
            visit login_path
            log_in_user('user@openstax.org', 'password')
            expect(page.current_url).to match(profile_newflow_path)
          end
        end
      end

      context 'user interface' do
        # example 'Forgot your password? link takes user to reset password form' do
        #   visit login_path
        #   expect(find('#forgot-passwork-link')['href']).to match(forgot_password_form_path)
        # end

        example 'SHOW/HIDE link for password field shows and hides password' do
          visit login_path
          expect(find('#login_form_password')['type']).to eq('password')
          find('#password-show-hide-button').click
          expect(find('#login_form_password')['type']).to eq('text')
          find('#password-show-hide-button').click
          expect(find('#login_form_password')['type']).to eq('password')
        end

        context 'when user clicks X icon' do
          context "when user arrived from oauth app" do
            let(:app) do
              FactoryBot.create(:doorkeeper_application, skip_terms: true,
                can_access_private_user_data: true,
                can_skip_oauth_screen: true)
            end

            before do
              FactoryBot.create(:doorkeeper_access_token, application: app, resource_owner_id: nil)
              app.update_columns(redirect_uri: external_public_url)
            end

            it 'takes user back to app' do
              with_forgery_protection do
                arrive_from_app(app: app)
                find('#exit-icon a').click
                wait_for_animations
                wait_for_ajax
                expect(page.current_url).to match(external_public_url)
              end
            end

            context 'when user goes to signup tab, then back to login tab' do
              scenario 'takes user back to the app' do
                with_forgery_protection do
                  arrive_from_app(app: app)
                  click_on(I18n.t(:'login_signup_form.sign_up'))
                  click_on(I18n.t(:'login_signup_form.log_in'))
                  find('#exit-icon a').click
                  wait_for_animations
                  wait_for_ajax
                  expect(page.current_url).to match(external_public_url)
                end
              end
            end
          end

          context "when user arrived with `r`eturn param" do
            it 'takes user back to `r`eturn url' do
              with_forgery_protection do
                visit(login_path(r: external_public_url))
                find('#exit-icon a').click
                wait_for_animations
                wait_for_ajax
                expect(page.current_url).to match(external_public_url)
              end
            end
          end
        end
      end
    end

    context 'when student has not verified their only email address' do
      let!(:user) { FactoryBot.create(:user, state: User::UNVERIFIED) }
      let!(:email_address) { FactoryBot.create(:email_address, user: user) }
      let!(:identity) { FactoryBot.create(:identity, user: user, password: 'password') }

      it 'allows the student to log in and redirects them to the email verification form' do
        visit(login_path)
        fill_in('login_form_email', with: email_address.value)
        fill_in('login_form_password', with: 'password')
        find('[type=submit]').click
        expect(page.current_path).to match(student_email_verification_form_path)
      end
    end

    context 'no user found with such email' do
      xit 'adds a message to the email input field' do
        with_forgery_protection do
          visit login_path
          log_in_user('NOone@openstax.org', 'password')
          expect(page.current_url).to match(login_path)
          field_text = find('#login_form_email + .errors.invalid-message').text
          expect(field_text).to  eq(I18n.t(:'login_signup_form.cannot_find_user'))
        end
      end
    end

    context 'wrong password for account with such email' do
      xit 'adds a message to the password input field' do
        with_forgery_protection do
            visit login_path
            log_in_user('user@openstax.org', 'WRONGpassword')
            expect(page.current_url).to match(login_path)
            field_text = find('#login_form_password + .errors.invalid-message').text
            expect(field_text).to  eq(I18n.t(:'login_signup_form.incorrect_password'))
          end
      end
    end

    context 'forgot password' do
      xit 'enables the user to reset their password' do
        with_forgery_protection do
          visit login_path
          screenshot!
          log_in_user('user@openstax.org', 'WRONGpassword')
          screenshot!

          click_on(I18n.t(:'login_signup_form.forgot_password'))
          expect(page).to have_content(I18n.t(:'login_signup_form.reset_my_password_description'))
          # pre-populates the email for them since they already typed it in the login form
          expect(find('#forgot_password_form_email')['value']).to eq('user@openstax.org')
          screenshot!
          click_on(I18n.t(:'login_signup_form.reset_my_password_button'))
          screenshot!

          expect(page).to have_content(I18n.t(:'login_signup_form.password_reset_email_sent'))
          screenshot!

          open_email('user@openstax.org')
          capture_email!
          change_password_link = get_path_from_absolute_link(current_email, 'a')
          expect(change_password_link).to include(change_password_form_path)

          # set the new password
          visit change_password_link
          expect(page).to have_content(I18n.t(:'login_signup_form.enter_new_password_description'))
          fill_in('change_password_form_password', with: 'NEWpassword')
          screenshot!
          find('#login-signup-form').click
          wait_for_animations
          click_button('Log in')
          screenshot!

          # user is subsequently able to log in with the new password
          click_on('Log out')
          screenshot!
          log_in_user('user@openstax.org', 'NEWpassword')
          expect(page).to  have_content('My Account')
        end
      end
    end

    # logging in with facebook and google is tested in unit tests as well as manually
  end
end
