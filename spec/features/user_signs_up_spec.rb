require 'spec_helper'

feature 'User signs up as a local user', js: true do
  scenario 'success' do
    visit '/'
    expect(page).to have_content('Sign Up or Sign in')
    click_link 'Sign Up'
    expect(page).to have_content('Register with a username and password')
    expect(page).to have_content('register using your Facebook, Twitter, or Google account.')

    fill_in 'Username', with: 'testuser'
    fill_in 'Password', with: 'password'
    fill_in 'Password Again', with: 'password'
    click_button 'Register'
    expect(page).to have_content('Welcome, testuser')

    click_link 'I have not made'
    expect(page).to have_content('Welcome, testuser')

    expect(page).to have_content('Complete your profile information')
    fill_in 'First Name', with: 'Test'
    fill_in 'Last Name', with: 'User'
    find(:css, '#register_i_agree').set(true)
    click_button 'Register'

    click_link 'Sign out'
    expect(page).to have_content('Signed out!')
    expect(page).not_to have_content('Welcome, testuser')
    expect(page).to have_content('Sign Up or Sign in')
  end

  scenario 'with incorrect password confirmation', js: true do
    visit '/'
    expect(page).to have_content('Sign Up or Sign in')
    click_link 'Sign Up'
    expect(page).to have_content('Register with a username and password')
    expect(page).to have_content('register using your Facebook, Twitter, or Google account.')

    fill_in 'Username', with: 'testuser'
    fill_in 'Password', with: 'password'
    fill_in 'Password Again', with: 'pass'
    click_button 'Register'
    expect(page).to have_content("Password doesn't match confirmation")
    expect(page).not_to have_content('Welcome, testuser')
  end

  scenario 'with empty username', js: true do
    visit '/'
    expect(page).to have_content('Sign Up or Sign in')
    click_link 'Sign Up'
    expect(page).to have_content('Register with a username and password')
    expect(page).to have_content('register using your Facebook, Twitter, or Google account.')

    fill_in 'Username', with: ''
    fill_in 'Password', with: 'password'
    fill_in 'Password Again', with: 'password'
    click_button 'Register'
    expect(page).to have_content("Alert: Username can't be blank")
    expect(page).not_to have_content('Welcome, testuser')
  end

  scenario 'with empty password', js: true do
    visit '/'
    expect(page).to have_content('Sign Up or Sign in')
    click_link 'Sign Up'
    expect(page).to have_content('Register with a username and password')
    expect(page).to have_content('register using your Facebook, Twitter, or Google account.')

    fill_in 'Username', with: 'testuser'
    fill_in 'Password', with: ''
    fill_in 'Password Again', with: ''
    click_button 'Register'
    expect(page).to have_content("Password can't be blank")
    expect(page).not_to have_content('Welcome, testuser')
  end

  scenario 'with short password', js: true do
    visit '/'
    expect(page).to have_content('Sign Up or Sign in')
    click_link 'Sign Up'
    expect(page).to have_content('Register with a username and password')
    expect(page).to have_content('register using your Facebook, Twitter, or Google account.')

    fill_in 'Username', with: 'testuser'
    fill_in 'Password', with: 'pass'
    fill_in 'Password Again', with: 'pass'
    click_button 'Register'
    expect(page).to have_content("Password is too short (minimum is 8 characters)")
    expect(page).not_to have_content('Welcome, testuser')
  end
end
