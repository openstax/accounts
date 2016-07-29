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

          fill_in 'Username', with: 'user'
          fill_in 'Password', with: SecureRandom.hex
          click_button 'Sign in'
          expect(page).to have_content('The password you provided is incorrect.')
        end

          visit '/'
        expect_sign_in_page

        fill_in 'Username', with: 'user'
        fill_in 'Password', with: SecureRandom.hex
        click_button 'Sign in'
        expect(page).to have_content('You have made too many login attempts recently.')

        visit '/'
        expect_sign_in_page

        fill_in 'Username', with: 'user'
        fill_in 'Password', with: 'password'
        click_button 'Sign in'
        expect(page).to have_content('You have made too many login attempts recently.')

        reset_code = generate_reset_code_for 'user'
        visit "/reset_password?code=#{reset_code}"
        expect(page).not_to have_content('Reset password link is invalid')
        expect(page).to have_content('Confirm Password')
        fill_in 'Password', with: '1234abcd'
        fill_in 'Confirm Password', with: '1234abcd'
        click_button 'Set Password'
        expect(page).to have_content(
          'Your password has been reset successfully! You are now signed in.'
        )

        click_link 'Sign out'

        visit '/'
        expect_sign_in_page

        fill_in 'Username', with: 'user'
        fill_in 'Password', with: '1234abcd'
        click_button 'Sign in'
        expect(page).to have_content('Welcome, user')
      end
    end

    scenario 'getting the user unblocked after 1 hour' do
      with_forgery_protection do
        create_user 'user'

        max_attempts_per_user.times do
          visit '/'
          expect_sign_in_page

          fill_in 'Username', with: 'user'
          fill_in 'Password', with: SecureRandom.hex
          click_button 'Sign in'
          expect(page).to have_content('The password you provided is incorrect.')
        end

          visit '/'
        expect_sign_in_page

        fill_in 'Username', with: 'user'
        fill_in 'Password', with: SecureRandom.hex
        click_button 'Sign in'
        expect(page).to have_content('You have made too many login attempts recently.')

        visit '/'
        expect_sign_in_page

        fill_in 'Username', with: 'user'
        fill_in 'Password', with: 'password'
        click_button 'Sign in'
        expect(page).to have_content('You have made too many login attempts recently.')

        Timecop.freeze(Time.now + OmniAuth::Strategies::CustomIdentity::LOGIN_ATTEMPTS_PERIOD) do
          visit '/'
          expect_sign_in_page

          fill_in 'Username', with: 'user'
          fill_in 'Password', with: 'password'
          click_button 'Sign in'
          expect(page).to have_content('Welcome, user')
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

          fill_in 'Username', with: 'user@example.com'
          fill_in 'Password', with: SecureRandom.hex
          click_button 'Sign in'
          expect(page).to have_content('The password you provided is incorrect.')
        end

        visit '/'
        expect_sign_in_page

        fill_in 'Username', with: 'user@example.com'
        fill_in 'Password', with: SecureRandom.hex
        click_button 'Sign in'
        expect(page).to have_content('You have made too many login attempts recently.')

        visit '/'
        expect_sign_in_page

        fill_in 'Username', with: 'user@example.com'
        fill_in 'Password', with: 'password'
        click_button 'Sign in'
        expect(page).to have_content('You have made too many login attempts recently.')

        reset_code = generate_reset_code_for 'user'
        visit "/reset_password?code=#{reset_code}"
        expect(page).not_to have_content('Reset password link is invalid')
        expect(page).to have_content('Confirm Password')
        fill_in 'Password', with: '1234abcd'
        fill_in 'Confirm Password', with: '1234abcd'
        click_button 'Set Password'
        expect(page).to have_content(
          'Your password has been reset successfully! You are now signed in.'
        )

        click_link 'Sign out'

        visit '/'
        expect_sign_in_page

        fill_in 'Username', with: 'user@example.com'
        fill_in 'Password', with: '1234abcd'
        click_button 'Sign in'
        expect(page).to have_content('Welcome, user')
      end
    end

    scenario 'getting the user unblocked after 1 hour' do
      with_forgery_protection do
        user = create_user 'user'
        create_email_address_for user, 'user@example.com'

        max_attempts_per_user.times do
          visit '/'
          expect_sign_in_page

          fill_in 'Username', with: 'user@example.com'
          fill_in 'Password', with: SecureRandom.hex
          click_button 'Sign in'
          expect(page).to have_content('The password you provided is incorrect.')
        end

        visit '/'
        expect_sign_in_page

        fill_in 'Username', with: 'user@example.com'
        fill_in 'Password', with: SecureRandom.hex
        click_button 'Sign in'
        expect(page).to have_content('You have made too many login attempts recently.')

        visit '/'
        expect_sign_in_page

        fill_in 'Username', with: 'user@example.com'
        fill_in 'Password', with: 'password'
        click_button 'Sign in'
        expect(page).to have_content('You have made too many login attempts recently.')

        Timecop.freeze(Time.now + OmniAuth::Strategies::CustomIdentity::LOGIN_ATTEMPTS_PERIOD) do
          visit '/'
          expect_sign_in_page

          fill_in 'Username', with: 'user@example.com'
          fill_in 'Password', with: 'password'
          click_button 'Sign in'
          expect(page).to have_content('Welcome, user')
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

          fill_in 'Username', with: SecureRandom.hex
          fill_in 'Password', with: SecureRandom.hex
          click_button 'Sign in'
          expect(page).to have_content('We have no account for the username or email you provided.')
        end

        visit '/'
        expect_sign_in_page

        fill_in 'Username', with: SecureRandom.hex
        fill_in 'Password', with: SecureRandom.hex
        click_button 'Sign in'
        expect(page).to have_content('You have made too many login attempts recently.')

        visit '/'
        expect_sign_in_page

        fill_in 'Username', with: 'user'
        fill_in 'Password', with: 'password'
        click_button 'Sign in'
        expect(page).to have_content('You have made too many login attempts recently.')

        Timecop.freeze(Time.now + OmniAuth::Strategies::CustomIdentity::LOGIN_ATTEMPTS_PERIOD) do
          visit '/'
          expect_sign_in_page

          fill_in 'Username', with: 'user'
          fill_in 'Password', with: 'password'
          click_button 'Sign in'
          expect(page).to have_content('Welcome, user')
        end
      end
    end
  end

end
