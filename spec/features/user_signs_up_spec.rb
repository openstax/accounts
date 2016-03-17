require 'rails_helper'

feature 'User signs up as a local user', js: true do
  scenario 'success' do
    create_application
    visit_authorize_uri

    expect(page).to have_content('Sign in with your one OpenStax account!')
    click_link 'Create password account'
    expect(page).to have_content('Create your account')

    fill_in 'First Name', with: 'Test'
    fill_in 'Last Name', with: 'User'
    fill_in 'Email Address', with: 'testuser@example.com'
    fill_in 'Username', with: 'testuser'
    fill_in 'Password *', with: 'password'
    fill_in 'Confirm Password', with: 'password'
    find(:css, '#register_i_agree').set(true)
    click_button 'Register'

    expect(page).not_to have_content('Alert')

    expect(page.current_url).to match(app_callback_url)

    visit '/'
    click_link 'Sign out'
    expect(page).to have_content('Signed out!')
    expect(page).not_to have_content('Welcome, testuser')
    expect(page).to have_content('Sign in with your one OpenStax account!')
  end

  scenario 'with incorrect password confirmation', js: true do
    visit '/'
    click_link 'Create password account'

    fill_in 'First Name', with: 'Test'
    fill_in 'Last Name', with: 'User'
    fill_in 'Email Address', with: 'testuser@example.com'
    fill_in 'Username', with: 'testuser'
    fill_in 'Password *', with: 'password'
    fill_in 'Confirm Password', with: 'pass'
    find(:css, '#register_i_agree').set(true)
    click_button 'Register'

    expect(page).to have_content("Alert: Password doesn't match confirmation")
    expect(page).not_to have_content('Sign out')
  end

  scenario 'with empty username', js: true do
    visit '/'
    click_link 'Create password account'

    fill_in 'First Name', with: 'Test'
    fill_in 'Last Name', with: 'User'
    fill_in 'Email Address', with: 'testuser@example.com'
    fill_in 'Username', with: ''
    fill_in 'Password *', with: 'password'
    fill_in 'Confirm Password', with: 'password'
    find(:css, '#register_i_agree').set(true)
    click_button 'Register'

    expect(page).to have_content("Alert: Username can't be blank")
    expect(page).not_to have_content('Sign out')
  end

  scenario 'with empty password', js: true do
    visit '/'
    click_link 'Create password account'

    fill_in 'First Name', with: 'Test'
    fill_in 'Last Name', with: 'User'
    fill_in 'Email Address', with: 'testuser@example.com'
    fill_in 'Username', with: 'testuser'
    fill_in 'Password *', with: ''
    fill_in 'Confirm Password', with: ''
    find(:css, '#register_i_agree').set(true)
    click_button 'Register'

    expect(page).to have_content("Alert: You must choose a password and confirm it to create your account")
    expect(page).not_to have_content('Sign out')
  end

  scenario 'with short password', js: true do
    visit '/'
    click_link 'Create password account'

    fill_in 'First Name', with: 'Test'
    fill_in 'Last Name', with: 'User'
    fill_in 'Email Address', with: 'testuser@example.com'
    fill_in 'Username', with: 'testuser'
    fill_in 'Password *', with: 'pass'
    fill_in 'Confirm Password', with: 'pass'
    find(:css, '#register_i_agree').set(true)
    click_button 'Register'

    expect(page).to have_content("Password is too short (minimum is 8 characters)")
    expect(page).not_to have_content('Sign out')
  end

  scenario 'with a username already taken' do
    create_user 'testuser'
    visit '/'
    click_link 'Create password account'

    fill_in 'First Name', with: 'Test'
    fill_in 'Last Name', with: 'User'
    fill_in 'Email Address', with: 'testuser@example.com'
    fill_in 'Username', with: 'testuser'
    fill_in 'Password *', with: 'password'
    fill_in 'Confirm Password', with: 'password'
    find(:css, '#register_i_agree').set(true)
    click_button 'Register'

    expect(page).to have_content('Username has already been taken', count: 1)
    expect(page).not_to have_content('Sign out')
  end

  scenario 'with empty email address', js: true do
    visit '/'
    click_link 'Create password account'

    fill_in 'First Name', with: 'Test'
    fill_in 'Last Name', with: 'User'
    fill_in 'Email Address', with: ''
    fill_in 'Username', with: 'testuser'
    fill_in 'Password *', with: 'password'
    fill_in 'Confirm Password', with: 'password'
    find(:css, '#register_i_agree').set(true)
    click_button 'Register'

    expect(page).to have_content("Alert: Email address can't be blank")
    expect(page).not_to have_content('Sign out')
  end

  scenario 'with an invalid email address' do
    visit '/'
    click_link 'Create password account'

    fill_in 'First Name', with: 'Test'
    fill_in 'Last Name', with: 'User'
    fill_in 'Email Address', with: 'testuser@ex ample.org'
    fill_in 'Username', with: 'testuser'
    fill_in 'Password *', with: 'password'
    fill_in 'Confirm Password', with: 'password'
    find(:css, '#register_i_agree').set(true)
    click_button 'Register'

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

    authentication = FactoryGirl.create(:authentication,
                                        user: user,
                                        provider: 'facebook')

    visit '/'
    signin_as 'bob'

    visit '/signup/social'

    allow(OSU::AccessPolicy).to receive(:action_allowed?).and_return(true)


    find(:css, '#register_i_agree').set(true)
    click_button 'Register'

    expect(page).not_to have_content("Alert: Email address can't be blank")
    expect(page).to have_content("Your Account")
  end
end
