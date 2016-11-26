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

        click_link (t :"layouts.application_header.sign_out")

        log_in_correctly_with_username(password: '1234abcd')
        # expect(page).to have_content(t :"layouts.application_header.welcome_html", username: 'user')
        expect_profile_page
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

        Timecop.freeze(Time.now + OmniAuth::Strategies::CustomIdentity::LOGIN_ATTEMPTS_PERIOD) do
          log_in_correctly_with_username
          expect_profile_page
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

        click_link (t :"layouts.application_header.sign_out")

        log_in_correctly_with_email(password: '1234abcd')
        expect_profile_page
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

        Timecop.freeze(Time.now + OmniAuth::Strategies::CustomIdentity::LOGIN_ATTEMPTS_PERIOD) do
          log_in_correctly_with_email
          expect_profile_page
          # expect(page).to have_content(t :"layouts.application_header.welcome_html", username: 'user')
        end
      end
    end
  end

  xcontext 'with random usernames' do
    # TODO the spec as written doesn't work because a bad username is not something we
    # take special note of any more (since we only test password/social auth after
    # user has already gotten past the username/email screen).  We could potentially
    # add a security_log event to detect when a bad username is entered and then test
    # that the IP address gets locked out here.
    #
    # If we do bring this spec back, we will need to update log_in_bad_everything
    # because that method expects to see the password page even tho the username is bad.
    scenario 'getting their ip unblocked after 1 hour' do
      with_forgery_protection do
        create_user 'user'

        max_attempts_per_ip.times do
          log_in_bad_everything
          expect(page).to have_content(t :"controllers.sessions.no_account_for_username_or_email")
        end

        log_in_bad_everything
        expect(page).to have_content(t :"controllers.sessions.too_many_login_attempts.content",
                                       reset_password: (t :"controllers.sessions.too_many_login_attempts.reset_password"))

        log_in_correctly_with_username
        expect(page).to have_content(t :"controllers.sessions.too_many_login_attempts.content",
                                       reset_password: (t :"controllers.sessions.too_many_login_attempts.reset_password"))

        Timecop.freeze(Time.now + OmniAuth::Strategies::CustomIdentity::LOGIN_ATTEMPTS_PERIOD) do
          log_in_correctly_with_username
          expect_profile_page
        end
      end
    end
  end

  def log_in_good_username_bad_password
    log_in('user', SecureRandom.hex)
  end

  def log_in_good_email_bad_password
    log_in('user@example.com', SecureRandom.hex)
  end

  def log_in_bad_everything
    log_in(SecureRandom.hex, SecureRandom.hex)
  end

  def log_in_correctly_with_username(password: 'password')
    log_in('user', password)
  end

  def log_in_correctly_with_email(password: 'password')
    log_in('user@example.com', password)
  end

  def reset_password(password:)
    login_token = generate_login_token_for 'user'
    visit "/reset_password?token=#{login_token}"
    expect(page).not_to have_content(t :"handlers.identities_reset_password.reset_link_is_invalid")
    expect(page).to have_content(t :"identities.confirm_password")
    fill_in (t :"identities.password"), with: password
    fill_in (t :"identities.confirm_password"), with: password
    click_button (t :"identities.set_password")
    expect(page).to have_content(
      t :"controllers.identities.password_reset_successfully"
    )
  end

end
