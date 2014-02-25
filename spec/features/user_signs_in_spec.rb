require 'spec_helper'

feature 'User logs in as a local user', js: true do

  scenario 'authenticates against the default (bcrypt) password hashes' do
    create_user 'user'
    visit '/'
    expect(page).to have_content('Sign Up or Sign in')
    click_link 'Sign in'

    fill_in 'Username', with: 'user'
    fill_in 'Password', with: 'pass'
    click_button 'Sign in'
    expect(page).to have_content('Incorrect username or password')
    expect(page).not_to have_content('Welcome, user')

    fill_in 'Username', with: 'user'
    fill_in 'Password', with: 'password'
    click_button 'Sign in'
    expect(page).to have_content('Welcome, user')
  end

  scenario 'authenticates against plone (ssha) password hashes' do
    create_user_with_plone_password
    visit '/'
    expect(page).to have_content('Sign Up or Sign in')
    click_link 'Sign in'

    fill_in 'Username', with: 'plone_user'
    fill_in 'Password', with: 'pass'
    click_button 'Sign in'
    expect(page).to have_content('Incorrect username or password')
    expect(page).not_to have_content('Welcome, plone_user')

    fill_in 'Username', with: 'plone_user'
    fill_in 'Password', with: 'password'
    click_button 'Sign in'
    expect(page).to have_content('Welcome, plone_user')
  end

  scenario 'with an unknown username' do
    visit '/'
    expect(page).to have_content('Sign Up or Sign in')
    click_link 'Sign in'

    fill_in 'Username', with: 'user'
    fill_in 'Password', with: 'password'
    click_button 'Sign in'
    expect(page).to have_content('Incorrect username or password')
    expect(page).not_to have_content('Welcome, user')
  end

end
