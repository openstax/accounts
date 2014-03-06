require 'spec_helper'

feature 'User logs in as a local user', js: true do

  scenario 'authenticates against the default (bcrypt) password hashes' do
    with_forgery_protection do
      create_application
      create_user 'user'
      visit_authorize_uri
      expect(page).to have_content("Sign in to #{@app.name} with your one OpenStax account!")

      fill_in 'Username', with: 'user'
      fill_in 'Password', with: 'pass'
      click_button 'Sign in'
      expect(page).to have_content('Incorrect username or password')

      fill_in 'Username', with: 'user'
      fill_in 'Password', with: 'password'
      click_button 'Sign in'
      expect(page.current_url).to match(app_callback_url)
    end
  end

  scenario 'authenticates against plone (ssha) password hashes' do
    with_forgery_protection do
      create_application
      create_user_with_plone_password
      visit_authorize_uri

      expect(page).to have_content("Sign in to #{@app.name} with your one OpenStax account!")
      fill_in 'Username', with: 'plone_user'
      fill_in 'Password', with: 'pass'
      click_button 'Sign in'
      expect(page).to have_content('Incorrect username or password')

      fill_in 'Username', with: 'plone_user'
      fill_in 'Password', with: 'password'
      click_button 'Sign in'
      expect(page.current_url).to match(app_callback_url)
    end
  end

  scenario 'with an unknown username' do
    with_forgery_protection do
      create_application
      visit_authorize_uri
      expect(page).to have_content("Sign in to #{@app.name} with your one OpenStax account!")

      fill_in 'Username', with: 'user'
      fill_in 'Password', with: 'password'
      click_button 'Sign in'
      expect(page).to have_content('Incorrect username or password')
    end
  end

  scenario 'with a password that is expired' do
    @user = create_user 'expired_password'
    identity = @user.identity
    identity.password_expires_at = 1.week.ago
    identity.save

    visit '/'
    expect(page).to have_content('Sign Up or Sign in')
    click_link 'Sign in'

    fill_in 'Username', with: 'expired_password'
    fill_in 'Password', with: 'password'
    click_button 'Sign in'

    expect(page).to have_content('Welcome, expired_password')
    expect(page).to have_content('Alert: Your password has expired')

    fill_in 'Password', with: 'Passw0rd!'
    fill_in 'Password Again', with: 'Passw0rd!'
    click_button 'Set Password'

    expect(page).to have_content('Your password has been reset successfully!')
    expect(page).not_to have_content('You can now sign in with your new password')

    click_link 'Sign out'
    expect(page).to have_content('Signed out!')
    click_link 'Sign in'

    fill_in 'Username', with: 'expired_password'
    fill_in 'Password', with: 'Passw0rd!'
    click_button 'Sign in'

    expect(page).to have_content('Welcome, expired_password')
    expect(page).not_to have_content('Your password has expired')
  end

end
