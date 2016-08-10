require 'rails_helper'

feature 'User gets blocked after multiple failed sign in attempts', js: true do
  let(:max_attempts_per_user) { 2 }
  let(:max_attempts_per_ip)   { max_attempts_per_user + 3 }

  background do
    stub_const 'OmniAuth::Strategies::CustomIdentity::MAX_LOGIN_ATTEMPTS_PER_USER',
               max_attempts_per_user
    stub_const 'OmniAuth::Strategies::CustomIdentity::MAX_LOGIN_ATTEMPTS_PER_IP',
               max_attempts_per_ip
  end

  context 'with a known username' do
    scenario 'getting the user unblocked after a password reset' do
      with_forgery_protection do
        create_user 'user'

        max_attempts_per_user.times do
          visit '/'
          expect_sign_in_page

          fill_in (t :"sessions.new.username_or_email"), with: 'user'
          fill_in (t :"sessions.new.password"), with: SecureRandom.hex
          click_button (t :"sessions.new.sign_in")
          expect(page).to have_no_missing_translations
          expect(page).to have_content(t :"controllers.sessions.incorrect_password")
        end

          visit '/'
        expect_sign_in_page

        fill_in (t :"sessions.new.username_or_email"), with: 'user'
        fill_in (t :"sessions.new.password"), with: SecureRandom.hex
        click_button (t :"sessions.new.sign_in")
        expect(page).to have_no_missing_translations
        expect(page).to have_content(t :"controllers.sessions.too_many_login_attempts.content",
                                       reset_password: (t :"controllers.sessions.too_many_login_attempts.reset_password"))

        visit '/'
        expect_sign_in_page

        fill_in (t :"sessions.new.username_or_email"), with: 'user'
        fill_in (t :"sessions.new.password"), with: 'password'
        click_button (t :"sessions.new.sign_in")
        expect(page).to have_no_missing_translations
        expect(page).to have_content(t :"controllers.sessions.too_many_login_attempts.content",
                                       reset_password: (t :"controllers.sessions.too_many_login_attempts.reset_password"))

        reset_code = generate_reset_code_for 'user'
        visit "/reset_password?code=#{reset_code}"
        expect(page).not_to have_content(t :"handlers.identities_reset_password.reset_link_is_invalid")
        expect(page).to have_content(t :"identities.reset_password.confirm_password")
        fill_in (t :"identities.reset_password.password"), with: '1234abcd'
        fill_in (t :"identities.reset_password.confirm_password"), with: '1234abcd'
        click_button (t :"identities.reset_password.set_password")
        expect(page).to have_content(
          t :"controllers.identities.password_reset_successfully"
        )

        click_link (t :"layouts.application_header.sign_out")

        visit '/'
        expect_sign_in_page

        fill_in (t :"sessions.new.username_or_email"), with: 'user'
        fill_in (t :"sessions.new.password"), with: '1234abcd'
        click_button (t :"sessions.new.sign_in")
        expect(page).to have_no_missing_translations
        expect(page).to have_content(t :"layouts.application_header.welcome_html", username: 'user')
      end
    end

    scenario 'getting the user unblocked after 1 hour' do
      with_forgery_protection do
        create_user 'user'

        max_attempts_per_user.times do
          visit '/'
          expect_sign_in_page

          fill_in (t :"sessions.new.username_or_email"), with: 'user'
          fill_in (t :"sessions.new.password"), with: SecureRandom.hex
          click_button (t :"sessions.new.sign_in")
          expect(page).to have_no_missing_translations
          expect(page).to have_content(t :"controllers.sessions.incorrect_password")
        end

          visit '/'
        expect_sign_in_page

        fill_in (t :"sessions.new.username_or_email"), with: 'user'
        fill_in (t :"sessions.new.password"), with: SecureRandom.hex
        click_button (t :"sessions.new.sign_in")
        expect(page).to have_no_missing_translations
        expect(page).to have_content(t :"controllers.sessions.too_many_login_attempts.content",
                                       reset_password: (t :"controllers.sessions.too_many_login_attempts.reset_password"))

        visit '/'
        expect_sign_in_page

        fill_in (t :"sessions.new.username_or_email"), with: 'user'
        fill_in (t :"sessions.new.password"), with: 'password'
        click_button (t :"sessions.new.sign_in")
        expect(page).to have_no_missing_translations
        expect(page).to have_content(t :"controllers.sessions.too_many_login_attempts.content",
                                       reset_password: (t :"controllers.sessions.too_many_login_attempts.reset_password"))

        Timecop.freeze(Time.now + OmniAuth::Strategies::CustomIdentity::LOGIN_ATTEMPTS_PERIOD) do
          visit '/'
          expect_sign_in_page

          fill_in (t :"sessions.new.username_or_email"), with: 'user'
          fill_in (t :"sessions.new.password"), with: 'password'
          click_button (t :"sessions.new.sign_in")
          expect(page).to have_no_missing_translations
          expect(page).to have_content(t :"layouts.application_header.welcome_html", username: 'user')
        end
      end
    end
  end

  context 'with a known verified email address' do
    scenario 'getting the user unblocked after a password reset' do
      with_forgery_protection do
        user = create_user 'user'
        create_email_address_for user, 'user@example.com'

        max_attempts_per_user.times do
          visit '/'
          expect_sign_in_page

          fill_in (t :"sessions.new.username_or_email"), with: 'user@example.com'
          fill_in (t :"sessions.new.password"), with: SecureRandom.hex
          click_button (t :"sessions.new.sign_in")
          expect(page).to have_no_missing_translations
          expect(page).to have_content(t :"controllers.sessions.incorrect_password")
        end

        visit '/'
        expect_sign_in_page

        fill_in (t :"sessions.new.username_or_email"), with: 'user@example.com'
        fill_in (t :"sessions.new.password"), with: SecureRandom.hex
        click_button (t :"sessions.new.sign_in")
        expect(page).to have_no_missing_translations
        expect(page).to have_content(t :"controllers.sessions.too_many_login_attempts.content",
                                       reset_password: (t :"controllers.sessions.too_many_login_attempts.reset_password"))

        visit '/'
        expect_sign_in_page

        fill_in (t :"sessions.new.username_or_email"), with: 'user@example.com'
        fill_in (t :"sessions.new.password"), with: 'password'
        click_button (t :"sessions.new.sign_in")
        expect(page).to have_no_missing_translations
        expect(page).to have_content(t :"controllers.sessions.too_many_login_attempts.content",
                                       reset_password: (t :"controllers.sessions.too_many_login_attempts.reset_password"))

        reset_code = generate_reset_code_for 'user'
        visit "/reset_password?code=#{reset_code}"
        expect(page).not_to have_content(t :"handlers.identities_reset_password.reset_link_is_invalid")
        expect(page).to have_content(t :"identities.reset_password.confirm_password")
        fill_in (t :"identities.reset_password.password"), with: '1234abcd'
        fill_in (t :"identities.reset_password.confirm_password"), with: '1234abcd'
        click_button (t :"identities.reset_password.set_password")
        expect(page).to have_content(
          t :"controllers.identities.password_reset_successfully"
        )

        click_link (t :"layouts.application_header.sign_out")

        visit '/'
        expect_sign_in_page

        fill_in (t :"sessions.new.username_or_email"), with: 'user@example.com'
        fill_in (t :"sessions.new.password"), with: '1234abcd'
        click_button (t :"sessions.new.sign_in")
        expect(page).to have_content(t :"layouts.application_header.welcome_html", username: 'user')
      end
    end

    scenario 'getting the user unblocked after 1 hour' do
      with_forgery_protection do
        user = create_user 'user'
        create_email_address_for user, 'user@example.com'

        max_attempts_per_user.times do
          visit '/'
          expect_sign_in_page

          fill_in (t :"sessions.new.username_or_email"), with: 'user@example.com'
          fill_in (t :"sessions.new.password"), with: SecureRandom.hex
          click_button (t :"sessions.new.sign_in")
          expect(page).to have_no_missing_translations
          expect(page).to have_content(t :"controllers.sessions.incorrect_password")
        end

        visit '/'
        expect_sign_in_page

        fill_in (t :"sessions.new.username_or_email"), with: 'user@example.com'
        fill_in (t :"sessions.new.password"), with: SecureRandom.hex
        click_button (t :"sessions.new.sign_in")
        expect(page).to have_no_missing_translations
        expect(page).to have_content(t :"controllers.sessions.too_many_login_attempts.content",
                                       reset_password: (t :"controllers.sessions.too_many_login_attempts.reset_password"))

        visit '/'
        expect_sign_in_page

        fill_in (t :"sessions.new.username_or_email"), with: 'user@example.com'
        fill_in (t :"sessions.new.password"), with: 'password'
        click_button (t :"sessions.new.sign_in")
        expect(page).to have_no_missing_translations
        expect(page).to have_content(t :"controllers.sessions.too_many_login_attempts.content",
                                       reset_password: (t :"controllers.sessions.too_many_login_attempts.reset_password"))

        Timecop.freeze(Time.now + OmniAuth::Strategies::CustomIdentity::LOGIN_ATTEMPTS_PERIOD) do
          visit '/'
          expect_sign_in_page

          fill_in (t :"sessions.new.username_or_email"), with: 'user@example.com'
          fill_in (t :"sessions.new.password"), with: 'password'
          click_button (t :"sessions.new.sign_in")
          expect(page).to have_no_missing_translations
          expect(page).to have_content(t :"layouts.application_header.welcome_html", username: 'user')
        end
      end
    end
  end

  context 'with random usernames' do
    scenario 'getting thier ip unblocked after 1 hour' do
      with_forgery_protection do
        create_user 'user'

        max_attempts_per_ip.times do
          visit '/'
          expect_sign_in_page

          fill_in (t :"sessions.new.username_or_email"), with: SecureRandom.hex
          fill_in (t :"sessions.new.password"), with: SecureRandom.hex
          click_button (t :"sessions.new.sign_in")
          expect(page).to have_no_missing_translations
          expect(page).to have_content(t :"controllers.sessions.no_account_for_username_or_email")
        end

        visit '/'
        expect_sign_in_page

        fill_in (t :"sessions.new.username_or_email"), with: SecureRandom.hex
        fill_in (t :"sessions.new.password"), with: SecureRandom.hex
        click_button (t :"sessions.new.sign_in")
        expect(page).to have_no_missing_translations
        expect(page).to have_content(t :"controllers.sessions.too_many_login_attempts.content",
                                       reset_password: (t :"controllers.sessions.too_many_login_attempts.reset_password"))

        visit '/'
        expect_sign_in_page

        fill_in (t :"sessions.new.username_or_email"), with: 'user'
        fill_in (t :"sessions.new.password"), with: 'password'
        click_button (t :"sessions.new.sign_in")
        expect(page).to have_no_missing_translations
        expect(page).to have_content(t :"controllers.sessions.too_many_login_attempts.content",
                                       reset_password: (t :"controllers.sessions.too_many_login_attempts.reset_password"))

        Timecop.freeze(Time.now + OmniAuth::Strategies::CustomIdentity::LOGIN_ATTEMPTS_PERIOD) do
          visit '/'
          expect_sign_in_page

          fill_in (t :"sessions.new.username_or_email"), with: 'user'
          fill_in (t :"sessions.new.password"), with: 'password'
          click_button (t :"sessions.new.sign_in")
          expect(page).to have_no_missing_translations
          expect(page).to have_content(t :"layouts.application_header.welcome_html", username: 'user')
        end
      end
    end
  end

end
