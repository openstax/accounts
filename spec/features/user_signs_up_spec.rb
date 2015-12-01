require 'spec_helper'

feature 'User signs up as a local user', js: true do
  scenario 'success' do
    visit '/'
    expect(page).to have_content('Sign in to your one OpenStax account!')
    click_link 'Sign up'
    expect(page).to have_content('Sign up')
    expect(page).to have_content('register using your Facebook, Twitter, or Google account.')

    fill_in 'Email Address', with: 'testuser@example.com'
    fill_in 'Username', with: 'testuser'
    fill_in 'Password', with: 'password'
    fill_in 'Password Again', with: 'password'
    click_button 'Register'
    expect(page).to have_content('Welcome, testuser')

    click_link 'Continue'
    expect(page).to have_content('A verification email has been sent')

    visit confirm_path(code: EmailAddress.last.confirmation_code)
    expect(page).to have_content('Success!')

    visit '/'

    expect(page).to have_content('Complete your profile information')
    find(:css, '#register_i_agree').set(true)
    click_button 'Register'

    expect(page).to have_content("First name can't be blank")
    expect(page).to have_content("Last name can't be blank")

    fill_in 'First Name', with: 'Test'
    fill_in 'Last Name', with: 'User'
    find(:css, '#register_i_agree').set(true)
    click_button 'Register'

    click_link 'Sign out'
    expect(page).to have_content('Signed out!')
    expect(page).not_to have_content('Welcome, testuser')
    expect(page).to have_content('Sign in to your one OpenStax account!')
  end

  scenario 'with incorrect password confirmation', js: true do
    visit '/'
    expect(page).to have_content('Sign in to your one OpenStax account!')
    click_link 'Sign up'
    expect(page).to have_content('Sign up')
    expect(page).to have_content('register using your Facebook, Twitter, or Google account.')

    fill_in 'Email Address', with: 'testuser@example.com'
    fill_in 'Username', with: 'testuser'
    fill_in 'Password', with: 'password'
    fill_in 'Password Again', with: 'pass'
    click_button 'Register'
    expect(page).to have_content("Password doesn't match confirmation")
    expect(page).not_to have_content('Welcome, testuser')
  end

  scenario 'with empty username', js: true do
    visit '/'
    expect(page).to have_content('Sign in to your one OpenStax account!')
    click_link 'Sign up'
    expect(page).to have_content('Sign up')
    expect(page).to have_content('register using your Facebook, Twitter, or Google account.')

    fill_in 'Email Address', with: 'testuser@example.com'
    fill_in 'Username', with: ''
    fill_in 'Password', with: 'password'
    fill_in 'Password Again', with: 'password'
    click_button 'Register'
    expect(page).to have_content("Alert: Username can't be blank")
    expect(page).not_to have_content('Welcome, testuser')
  end

  scenario 'with empty password', js: true do
    visit '/'
    expect(page).to have_content('Sign in to your one OpenStax account!')
    click_link 'Sign up'
    expect(page).to have_content('Sign up')
    expect(page).to have_content('register using your Facebook, Twitter, or Google account.')

    fill_in 'Email Address', with: 'testuser@example.com'
    fill_in 'Username', with: 'testuser'
    fill_in 'Password', with: ''
    fill_in 'Password Again', with: ''
    click_button 'Register'
    expect(page).to have_content("Password can't be blank")
    expect(page).not_to have_content('Welcome, testuser')
  end

  scenario 'with short password', js: true do
    visit '/'
    expect(page).to have_content('Sign in to your one OpenStax account!')
    click_link 'Sign up'
    expect(page).to have_content('Sign up')
    expect(page).to have_content('register using your Facebook, Twitter, or Google account.')

    fill_in 'Email Address', with: 'testuser@example.com'
    fill_in 'Username', with: 'testuser'
    fill_in 'Password', with: 'pass'
    fill_in 'Password Again', with: 'pass'
    click_button 'Register'
    expect(page).to have_content("Password is too short (minimum is 8 characters)")
    expect(page).not_to have_content('Welcome, testuser')
  end

  scenario 'with empty email address', js: true do
    visit '/'
    expect(page).to have_content('Sign in to your one OpenStax account!')
    click_link 'Sign up'
    expect(page).to have_content('Sign up')
    expect(page).to have_content('register using your Facebook, Twitter, or Google account.')

    fill_in 'Email Address', with: ''
    fill_in 'Username', with: 'testuser'
    fill_in 'Password', with: 'password'
    fill_in 'Password Again', with: 'password'
    click_button 'Register'
    expect(page).to have_content("Email can't be blank")
    expect(page).not_to have_content('Welcome, testuser')
  end

  scenario 'without confirming email' do
    visit '/'
    expect(page).to have_content('Sign in to your one OpenStax account!')
    click_link 'Sign up'
    expect(page).to have_content('Sign up')
    expect(page).to have_content('register using your Facebook, Twitter, or Google account.')

    fill_in 'Email Address', with: 'testuser@example.com'
    fill_in 'Username', with: 'testuser'
    fill_in 'Password', with: 'password'
    fill_in 'Password Again', with: 'password'
    click_button 'Register'
    expect(page).to have_content('Welcome, testuser')

    click_link 'Continue'
    expect(page).to have_content('A verification email has been sent')

    click_link 'Sign out'
    fill_in 'Username / Email', with: 'testuser'
    fill_in 'Password', with: 'password'
    click_button 'Sign in'

    expect(page).to have_content('Welcome, testuser')
    click_link 'Continue'
    expect(page).to have_content('A verification email has been sent')
  end
end



