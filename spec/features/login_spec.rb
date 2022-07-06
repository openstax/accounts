require 'rails_helper'

feature 'login', js: true do
  before do
    load 'db/seeds.rb' # creates terms of use and privacy policy contracts
    create_user('user@openstax.org', 'password')
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
          create_user('needs_profile_user@openstax.org', 'password', false)
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
          expect(page.current_url).to match(profile_path)
        end
      end
    end

    context 'user interface' do
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
            app.update_column(:redirect_uri, external_public_url)
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
                click_on(I18n.t(:"login_signup_form.sign_up"))
                click_on(I18n.t(:"login_signup_form.log_in"))
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
      expect(page.current_path).to match(verify_email_by_pin_form_path)
    end
  end
end
