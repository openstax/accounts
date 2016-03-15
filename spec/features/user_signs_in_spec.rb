require 'rails_helper'

feature 'User logs in as a local user', js: true do

  scenario 'authenticates against the default (bcrypt) password hashes' do
    with_forgery_protection do
      create_application
      create_user 'user'
      visit_authorize_uri
      expect(page).to have_content("Sign in with your one OpenStax account!")

      fill_in 'Username', with: 'user'
      fill_in 'Password', with: 'pass'
      click_button 'Sign in'
      expect(page).to have_content('Incorrect username, email, or password')

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

      expect(page).to have_content("Sign in with your one OpenStax account!")
      fill_in 'Username', with: 'plone_user'
      fill_in 'Password', with: 'pass'
      click_button 'Sign in'
      expect(page).to have_content('Incorrect username, email, or password')

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
      expect(page).to have_content("Sign in with your one OpenStax account!")

      fill_in 'Username', with: 'user'
      fill_in 'Password', with: 'password'
      click_button 'Sign in'
      expect(page).to have_content('Incorrect username, email, or password')
    end
  end

  scenario 'with a password that is expired' do
    @user = create_user 'expired_password'
    identity = @user.identity
    identity.password_expires_at = 1.week.ago
    identity.save

    with_forgery_protection do
      create_application
      visit_authorize_uri
      expect(page).to have_content("Sign in with your one OpenStax account!")

      fill_in 'Username', with: 'expired_password'
      fill_in 'Password', with: 'password'
      click_button 'Sign in'

      expect(page).to have_content('Welcome, expired_password')
      expect(page).to have_content('Alert: Your password has expired')

      fill_in 'Password', with: 'Passw0rd!'
      fill_in 'Password Again', with: 'Passw0rd!'
      click_button 'Set Password'

      expect(page.current_url).to match(app_callback_url)
    end
  end

  scenario 'with a user imported from csv' do
    imported_user 'imported_user'

    with_forgery_protection do
      create_application
      visit_authorize_uri
      expect(page).to have_content("Sign in with your one OpenStax account!")

      fill_in 'Username', with: 'imported_user'
      fill_in 'Password', with: 'password'
      click_button 'Sign in'

      expect(page).to have_content('Welcome, imported_user')
      expect(page).to have_content('Alert: Your password has expired')

      fill_in 'Password', with: 'Passw0rd!'
      fill_in 'Password Again', with: 'Passw0rd!'
      click_button 'Set Password'

      expect(page).to have_content('Terms of Use')

      find(:css, '#agreement_i_agree').set(true)
      click_button 'Agree'

      expect(page).to have_content('Privacy Policy')
      find(:css, '#agreement_i_agree').set(true)
      click_button 'Agree'

      expect(page.current_url).to match(app_callback_url)
    end
  end

  scenario 'redirect home page visitors' do
    user = create_user('jimbo')

    visit '/'
    expect(page).to have_content('Sign in with your one OpenStax account')

    login_as 'jimbo', 'password'

    visit '/'
    expect(page).to have_content('Your Account')
  end

  scenario 'and gets asked to reset password and accept terms on home page' do
    imported_user 'imported_user'

    with_forgery_protection do
      create_application
      visit '/'
      expect(page).to have_content('Sign in with your one OpenStax account')

      fill_in 'Username', with: 'imported_user'
      fill_in 'Password', with: 'password'
      click_button 'Sign in'

      expect(page).to have_content('Welcome, imported_user')
      expect(page).to have_content('Alert: Your password has expired')

      fill_in 'Password', with: 'Passw0rd!'
      fill_in 'Password Again', with: 'Passw0rd!'
      click_button 'Set Password'

      expect(page).to have_content('Terms of Use')

      find(:css, '#agreement_i_agree').set(true)
      click_button 'Agree'

      expect(page).to have_content('Privacy Policy')
      find(:css, '#agreement_i_agree').set(true)
      click_button 'Agree'

      expect(current_path).to eq profile_path
    end
  end

  scenario 'keeps trying to find existing account when signing in' do
    create_user('jimbo')

    visit '/login'
    expect(page).to have_content("Sign in with your one OpenStax account!")

    click_omniauth_link('twitter')

    expect(page).to have_content('Merge Logins')
    expect(page).to have_no_link('twitter-login-button')

    click_omniauth_link('google_oauth2')

    expect(page).to have_content('Merge Logins')
    expect(page).to have_no_link('twitter-login-button')
    expect(page).to have_no_link('google_oauth2-login-button')

    click_omniauth_link('facebook')

    expect(page).to have_content('Merge Logins')
    expect(page).to have_no_link('twitter-login-button')
    expect(page).to have_no_link('google_oauth2-login-button')
    expect(page).to have_no_link('facebook-login-button')
    expect(page).to have_no_content('left-or-block')

    fill_in 'Username', with: 'jimbo'
    fill_in 'Password', with: 'password'

    click_button 'Sign in'

    expect(page).to have_no_content('Merge Logins')
    expect(page).to have_no_content('Sign in with your one')
  end

  scenario 'a user signs into an account that has been created by an admin for them', js: true do

    new_user = FindOrCreateUnclaimedUser.call(
      email:'unclaimeduser@example.com', username: 'therulerofallthings',
      password: "apassword", password_confirmation: "apassword"
    ).outputs.user
    expect(new_user.reload.state).to eq("unclaimed")

    with_forgery_protection do
      create_application
      visit_authorize_uri
      expect(page).to have_content("Sign in with your one OpenStax account!")

      fill_in 'Username', with: 'therulerofallthings'
      fill_in 'Password', with: 'apassword'
      click_button 'Sign in'

      expect(page).to have_content('Alert: Your password has expired')
      expect(new_user.reload.state).to eq("activated")
    end

  end

  scenario 'with an email address and password' do
    with_forgery_protection do
      create_application
      user = create_user 'user'
      create_email_address_for user, 'user@example.com'
      visit_authorize_uri
      expect(page).to have_content("Sign in with your one OpenStax account!")

      fill_in 'Username', with: 'user'
      fill_in 'Password', with: 'pass'
      click_button 'Sign in'
      expect(page).to have_content('Incorrect username, email, or password')

      fill_in 'Username or Email', with: 'user@example.com'
      fill_in 'Password', with: 'password'
      click_button 'Sign in'
      expect(page.current_url).to match(app_callback_url)
    end
  end
end
