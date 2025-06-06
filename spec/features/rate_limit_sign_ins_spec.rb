require 'rails_helper'

feature 'User gets blocked after multiple failed sign in attempts', js: true do
  let(:max_attempts_per_user) { 2 }
  let(:max_attempts_per_ip)   { max_attempts_per_user + 3 }

  background do
    stub_const 'RateLimiting::MAX_LOGIN_ATTEMPTS_PER_USER', max_attempts_per_user
    stub_const 'RateLimiting::MAX_LOGIN_ATTEMPTS_PER_IP', max_attempts_per_ip
  end

  context 'with a known username' do
    scenario 'getting the user unblocked after a password reset' do
      with_forgery_protection do
        create_user 'user'

        max_attempts_per_user.times do
          log_in_good_username_bad_password
          expect(page).to have_content(t :"controllers.sessions.incorrect_password")
        end

        log_in_good_username_bad_password
        expect(page).to have_content(t :"controllers.sessions.too_many_login_attempts.content",
                                       reset_password: (t :"controllers.sessions.too_many_login_attempts.reset_password"))

        log_in_correctly_with_username
        expect(page).to have_content(t :"controllers.sessions.too_many_login_attempts.content",
                                       reset_password: (t :"controllers.sessions.too_many_login_attempts.reset_password"))

        reset_password(password: '1234abcd')

        click_link_or_button (t :"legacy.users.edit.sign_out")

        log_in_correctly_with_username(password: '1234abcd')
        # expect(page).to have_content(t :"layouts.application_header.welcome_html", username: 'user')
        expect_newflow_profile_page
      end
    end

    scenario 'getting the user unblocked after 1 hour' do
      with_forgery_protection do
        create_user 'user'

        max_attempts_per_user.times do
          log_in_good_username_bad_password
          expect(page).to have_content(t :"controllers.sessions.incorrect_password")
        end

        log_in_good_username_bad_password
        expect(page).to have_content(t :"controllers.sessions.too_many_login_attempts.content",
                                       reset_password: (t :"controllers.sessions.too_many_login_attempts.reset_password"))

        log_in_correctly_with_username
        expect(page).to have_content(t :"controllers.sessions.too_many_login_attempts.content",
                                       reset_password: (t :"controllers.sessions.too_many_login_attempts.reset_password"))

        Timecop.freeze(Time.now + RateLimiting::LOGIN_ATTEMPTS_PERIOD) do
          log_in_correctly_with_username
          expect_newflow_profile_page
          # expect(page).to have_content(t :"layouts.application_header.welcome_html", username: 'user')
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
          log_in_good_email_bad_password
          expect(page).to have_content(t :"controllers.sessions.incorrect_password")
        end

        log_in_good_email_bad_password
        expect(page).to have_content(t :"controllers.sessions.too_many_login_attempts.content",
                                       reset_password: (t :"controllers.sessions.too_many_login_attempts.reset_password"))

        log_in_correctly_with_email
        expect(page).to have_content(t :"controllers.sessions.too_many_login_attempts.content",
                                       reset_password: (t :"controllers.sessions.too_many_login_attempts.reset_password"))

        reset_password(password: '1234abcd')

        click_link_or_button (t :"legacy.users.edit.sign_out")

        log_in_correctly_with_email(password: '1234abcd')
        expect_newflow_profile_page
        # expect(page).to have_content(t :"layouts.application_header.welcome_html", username: 'user')
      end
    end

    scenario 'getting the user unblocked after 1 hour' do
      with_forgery_protection do
        user = create_user 'user'
        create_email_address_for user, 'user@example.com'

        max_attempts_per_user.times do
          log_in_good_email_bad_password
          expect(page).to have_content(t :"controllers.sessions.incorrect_password")
        end

        log_in_good_email_bad_password
        expect(page).to have_content(t :"controllers.sessions.too_many_login_attempts.content",
                                       reset_password: (t :"controllers.sessions.too_many_login_attempts.reset_password"))

        log_in_correctly_with_email
        expect(page).to have_content(t :"controllers.sessions.too_many_login_attempts.content",
                                       reset_password: (t :"controllers.sessions.too_many_login_attempts.reset_password"))

        Timecop.freeze(Time.now + RateLimiting::LOGIN_ATTEMPTS_PERIOD) do
          log_in_correctly_with_email
          expect_newflow_profile_page
          # expect(page).to have_content(t :"layouts.application_header.welcome_html", username: 'user')
        end
      end
    end
  end

  context 'with random usernames' do
    scenario 'getting their ip unblocked after 1 hour' do
      with_forgery_protection do
        create_user 'user'

        max_attempts_per_ip.times do
          enter_bad_username
          expect(page).to have_content(t :"login_signup_form.cannot_find_user")
        end

        # Legacy would prevent this message and just return too_many_lookup_attempts at this point,
        # but Newflow allows it instead
        enter_bad_username
        expect(page).to have_content(t :"login_signup_form.cannot_find_user")

        enter_good_username
        expect(page).to have_content(t :"login_signup_form.too_many_login_attempts")

        Timecop.freeze(Time.now + RateLimiting::LOGIN_ATTEMPTS_PERIOD) do
          log_in_correctly_with_username
          expect_newflow_profile_page
        end
      end
    end
  end

  def log_in_good_username_bad_password
    newflow_log_in_user('user', SecureRandom.hex)
  end

  def log_in_good_email_bad_password
    newflow_log_in_user('user@example.com', SecureRandom.hex)
  end

  def enter_bad_username
    visit '/'
    complete_newflow_log_in_screen(SecureRandom.hex)
  end

  def enter_good_username
    visit '/'
    complete_newflow_log_in_screen('user')
  end

  def log_in_correctly_with_username(password: 'password')
    newflow_log_in_user('user', password)
  end

  def log_in_correctly_with_email(password: 'password')
    newflow_log_in_user('user@example.com', password)
  end

  def reset_password(password:)
    login_token = generate_login_token_for 'user'
    visit password_reset_path(token: login_token)
    complete_reset_password_screen(password)
    complete_reset_password_success_screen
  end

end
