require 'rails_helper'

module Newflow
  feature 'student login flow', js: true do
    before do
      load 'db/seeds.rb' # creates terms of use and privacy policy contracts
      create_newflow_user('user@openstax.org', 'password')

      turn_on_student_feature_flag
    end

    context 'happy path' do
      describe 'using SSO cookie' do
        it 'sends the student back to the specified return URL' do
          with_forgery_protection do
            visit newflow_login_path(r: capybara_url(external_app_for_specs_path))
            screenshot!
            complete_newflow_log_in_screen('user@openstax.org', 'password')
            expect(page).to have_current_path(external_app_for_specs_path)
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
              complete_newflow_log_in_screen('user@openstax.org', 'password')
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
              complete_newflow_log_in_screen('needs_profile_user@openstax.org', 'password')
              screenshot!
              expect(page).to have_current_path(signup_profile_path)
            end
          end
        end
      end

      describe 'with no return parameter specified, when feature flag is on' do
        before do
          turn_on_student_feature_flag
        end

        it 'sends the student to their profile' do
          with_forgery_protection do
            visit newflow_login_path
            complete_newflow_log_in_screen('user@openstax.org', 'password')
            expect(page).to have_current_path(profile_newflow_path)
          end
        end
      end

      context 'user interface' do

        example 'SHOW/HIDE link for password field shows and hides password' do
          visit newflow_login_path
          expect(find('#login_form_password')['type']).to eq('password')
          find('#password-show-hide-button').click
          expect(find('#login_form_password')['type']).to eq('text')
          find('#password-show-hide-button').click
          expect(find('#login_form_password')['type']).to eq('password')
        end

        example 'banners show up when there are any' do
          Banner.create(message: 'This is a banner.', expires_at: 1.day.from_now)
          Banner.create(message: 'This is another banner.', expires_at: 1.day.from_now)
          visit newflow_login_path
          expect(page).to have_text('This is a banner.')
          expect(page).to have_text('This is another banner.')
          screenshot!
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
              app.update_column(:redirect_uri, external_public_url)
            end

            it 'takes user back to app' do
              with_forgery_protection do
                arrive_from_app(app: app)
                find('#exit-icon').click
                wait_for_animations
                wait_for_ajax
                expect(page).to have_current_path(external_public_path)
              end
            end

            context 'when user goes to signup tab, then back to login tab' do
              scenario 'takes user back to the app' do
                with_forgery_protection do
                  arrive_from_app(app: app)
                  click_on(I18n.t(:"login_signup_form.sign_up"))
                  click_on(I18n.t(:"login_signup_form.log_in"))
                  find('#exit-icon').click
                  wait_for_animations
                  wait_for_ajax
                  expect(page).to have_current_path(external_public_path)
                end
              end
            end
          end

          context "when user arrived with `r`eturn param" do
            it 'takes user back to `r`eturn url' do
              with_forgery_protection do
                visit(newflow_login_path(r: external_public_url))
                find('#exit-icon').click
                wait_for_animations
                wait_for_ajax
                expect(page).to have_current_path(external_public_path)
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
        visit(newflow_login_path)
        fill_in('login_form_email', with: email_address.value)
        fill_in('login_form_password', with: 'password')
        find('[type=submit]').click
        expect(page).to have_current_path(student_email_verification_form_path)
      end
    end
  end
end
