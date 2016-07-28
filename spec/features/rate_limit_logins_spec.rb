require 'rails_helper'

feature 'User gets blocked after multiple failed login attempts', js: true do
  let(:max_attempts_per_user) { 3 }
  let(:max_attempts_per_ip)   { 5 }

  background do
    stub_const 'OmniAuth::Strategies::CustomIdentity::MAX_LOGIN_ATTEMPTS_PER_USER',
               max_attempts_per_user
    stub_const 'OmniAuth::Strategies::CustomIdentity::MAX_LOGIN_ATTEMPTS_PER_IP',
               max_attempts_per_ip
  end

  scenario 'with a known username' do
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

  scenario 'with a known verified email address' do
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

  scenario 'with random usernames' do
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
