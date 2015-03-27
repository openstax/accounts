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

    with_forgery_protection do
      create_application
      visit_authorize_uri
      expect(page).to have_content("Sign in to #{@app.name} with your one OpenStax account!")

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
      expect(page).to have_content("Sign in to #{@app.name} with your one OpenStax account!")

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

  scenario 'and gets asked to reset password and accept terms on home page' do
    imported_user 'imported_user'

    with_forgery_protection do
      create_application
      visit "/login"
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

      expect(current_path).to eq root_path
    end
  end

  scenario 'keeps trying to find existing account when signing in' do
    user = create_user('jimbo')
    i = user.identity

    visit '/'
    expect(page).to have_content('Sign up or Sign in')
    click_link 'Sign in'
    expect(page).to have_content("Sign in with your one OpenStax account!")

    click_omniauth_link('twitter')

    expect(page).to have_content('Nice to meet you,')
    expect(page).to have_no_link('twitter-login-button')

    click_omniauth_link('google_oauth2')

    expect(page).to have_content('Nice to meet you (again),')
    expect(page).to have_no_link('twitter-login-button')
    expect(page).to have_no_link('google_oauth2-login-button')

    click_omniauth_link('facebook')

    expect(page).to have_content('Nice to meet you (again),')
    expect(page).to have_no_link('twitter-login-button')
    expect(page).to have_no_link('google_oauth2-login-button')
    expect(page).to have_no_link('facebook-login-button')
    expect(page).to have_no_content('left-or-block')

    fill_in 'Username', with: 'jimbo'
    fill_in 'Password', with: 'password'

    click_button 'Sign in'

    expect(page).to have_no_content('Nice to meet')
    expect(page).to have_no_content('Sign in with your one')
  end

end
