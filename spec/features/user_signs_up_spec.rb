require 'rails_helper'

feature 'User signs up as a local user', js: true do

  background { load 'db/seeds.rb' }

  scenario 'success' do
    create_application
    visit_authorize_uri

    expect(page.current_url).to include(signin_path)
    click_password_sign_up
    expect(page).to have_content('Create Account')

    fill_in 'First Name', with: 'Test'
    fill_in 'Last Name', with: 'User'
    fill_in 'Email Address', with: 'testuser@example.com'
    fill_in 'Username', with: 'testuser'
    fill_in 'Password *', with: 'password'
    fill_in 'Confirm Password', with: 'password'
    agree_and_click_create

    expect(page).not_to have_content('Alert')

    expect(page.current_url).to match(app_callback_url)

    visit '/'
    click_link 'Sign out'
    expect(page.current_url).to include(signin_path)
    expect(page).not_to have_content('Welcome, testuser')
    expect(page.current_url).to include(signin_path)
  end

  scenario 'sign up chooser page' do
    create_application
    visit_authorize_uri

    expect_sign_in_page
    click_link 'Sign up'
    expect(page).to have_content('Sign up with OpenStax')
    expect(page).to have_content('Facebook')
    expect(page).to have_content('Google')
    expect(page).to have_content('Twitter')
    expect(page).to have_content('a password')
  end

  scenario 'with incorrect password confirmation' do
    visit '/'
    click_password_sign_up

    fill_in 'First Name', with: 'Test'
    fill_in 'Last Name', with: 'User'
    fill_in 'Email Address', with: 'testuser@example.com'
    fill_in 'Username', with: 'testuser'
    fill_in 'Password *', with: 'password'
    fill_in 'Confirm Password', with: 'pass'
    agree_and_click_create

    expect(page).to have_content("Alert: Password doesn't match confirmation")
    expect(page).not_to have_content('Sign out')
  end

  scenario 'with empty username' do
    visit '/'
    click_password_sign_up

    fill_in 'First Name', with: 'Test'
    fill_in 'Last Name', with: 'User'
    fill_in 'Email Address', with: 'testuser@example.com'
    fill_in 'Username', with: ''
    fill_in 'Password *', with: 'password'
    fill_in 'Confirm Password', with: 'password'
    agree_and_click_create

    expect(page).to have_content("Alert: Username can't be blank")
    expect(page).not_to have_content('Sign out')
  end

  scenario 'with empty password' do
    visit '/'
    click_password_sign_up

    fill_in 'First Name', with: 'Test'
    fill_in 'Last Name', with: 'User'
    fill_in 'Email Address', with: 'testuser@example.com'
    fill_in 'Username', with: 'testuser'
    fill_in 'Password *', with: ''
    fill_in 'Confirm Password', with: ''
    agree_and_click_create

    expect(page).to have_content("Alert: Password can't be blank Password confirmation can't be blank")
    expect(page).not_to have_content('Sign out')
  end

  scenario 'with short password' do
    visit '/'
    click_password_sign_up

    fill_in 'First Name', with: 'Test'
    fill_in 'Last Name', with: 'User'
    fill_in 'Email Address', with: 'testuser@example.com'
    fill_in 'Username', with: 'testuser'
    fill_in 'Password *', with: 'pass'
    fill_in 'Confirm Password', with: 'pass'
    agree_and_click_create

    expect(page).to have_content("Password is too short (minimum is 8 characters)")
    expect(page).not_to have_content('Sign out')
  end

  scenario 'with a username already taken' do
    create_user 'testuser'
    visit '/'
    click_password_sign_up

    fill_in 'First Name', with: 'Test'
    fill_in 'Last Name', with: 'User'
    fill_in 'Email Address', with: 'testuser@example.com'
    fill_in 'Username', with: 'testuser'
    fill_in 'Password *', with: 'password'
    fill_in 'Confirm Password', with: 'password'
    agree_and_click_create

    expect(page).to have_content('Username has already been taken', count: 1)
    expect(page).not_to have_content('Sign out')
  end

  scenario 'with empty email address' do
    visit '/'
    click_password_sign_up

    fill_in 'First Name', with: 'Test'
    fill_in 'Last Name', with: 'User'
    fill_in 'Email Address', with: ''
    fill_in 'Username', with: 'testuser'
    fill_in 'Password *', with: 'password'
    fill_in 'Confirm Password', with: 'password'
    agree_and_click_create

    expect(page).to have_content("Alert: Email address can't be blank")
    expect(page).not_to have_content('Sign out')
  end

  scenario 'with an invalid email address' do
    visit '/'
    click_password_sign_up

    fill_in 'First Name', with: 'Test'
    fill_in 'Last Name', with: 'User'
    fill_in 'Email Address', with: 'testuser@ex ample.org'
    fill_in 'Username', with: 'testuser'
    fill_in 'Password *', with: 'password'
    fill_in 'Confirm Password', with: 'password'
    agree_and_click_create

    expect(page).to have_content('Value "testuser@ex ample.org" is not a valid email address')
    expect(page).not_to have_content('Welcome, testuser')
  end

  scenario 'without any email addresses' do
    # this is a test for twitter users who have no email addresses

    # Some shenanigans to fake social sign up
    user = create_user 'bob'
    user.first_name = "Bob"
    user.last_name = "Henry"
    user.save

    authentication = FactoryGirl.create(:authentication, user: user, provider: 'twitter')

    visit '/'
    signin_as 'bob'

    visit '/signup/social'

    allow(OSU::AccessPolicy).to receive(:action_allowed?).and_return(true)

    agree_and_click_create

    expect(page).to have_content("Alert: You must provide an email address to create your account.")
    expect(page).to_not have_content("Your Account")

    fill_in 'Email Address', with: 'bob@example.org'
    click_button 'Create'

    expect(page).to_not have_content("Alert: You must provide an email address to create your account.")
    expect(page).to have_content("Your Account")
  end

  scenario 'when already has password' do
    visit '/'
    click_password_sign_up

    fill_in 'First Name', with: 'Test'
    fill_in 'Last Name', with: 'User'
    fill_in 'Email Address', with: 'testuser@example.com'
    fill_in 'Username', with: 'testuser'
    fill_in 'Password *', with: 'password'
    fill_in 'Confirm Password', with: 'password'
    agree_and_click_create

    visit '/signup/password'
    expect(page).to have_content("You already have a username and password")
    expect(page).to have_content("Your Account")
  end

  scenario 'not fully signed up social user goes elsewhere' do
    # Some shenanigans to fake social sign up
    user = create_user 'bob'
    user.first_name = "Bob"
    user.last_name = "Henry"
    user.state = 'new_social'
    user.save

    authentication = FactoryGirl.create(:authentication, user: user, provider: 'twitter')

    visit '/'
    signin_as 'bob'

    ['/profile', '/signin'].each do |path|
      visit path
      expect_social_sign_up_page
    end

    visit '/signout'
    expect(page).to have_current_path signin_path
  end

end
