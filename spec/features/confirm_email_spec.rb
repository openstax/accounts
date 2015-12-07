require 'spec_helper'

feature 'Confirm email address', js: true do
  background do
    user = create_user 'user'
    create_email_address_for user, 'user@example.com', '1111'
  end

  scenario 'successfully' do
    visit '/confirm?code=1111'
    expect(page).to have_content('Email Verification Success!')
  end

  scenario 'without a confirmation code' do
    visit '/confirm'
    expect(page).to have_content("Sorry, we couldn't verify an email using the verification code you provided.")
  end

  scenario 'with unmatched confirmation code' do
    visit '/confirm?code=1234'
    expect(page).to have_content("Sorry, we couldn't verify an email using the verification code you provided.")
  end

  scenario 'redirects back to site afterwards' do
    # set the user state to "temp" so we can test registration
    user = create_user 'user2'
    user.state = 'temp'
    user.save

    create_application
    visit_authorize_uri
    fill_in 'Username', with: 'user2'
    fill_in 'Password', with: 'password'
    click_on 'Sign in'

    # this page is not being used in the current registration workflow
    # but the code is there in case we want to use it
    visit '/ask_for_email'
    fill_in 'Email Address', with: 'user2@example.com'
    click_on 'Submit'

    expect(page).to have_content('A verification email has been sent')
    visit link_in_last_email

    expect(page).to have_content('Complete your profile')
    fill_in 'First Name', with: 'User'
    fill_in 'Last Name', with: 'Two'
    find(:css, '#register_i_agree').set(true)
    click_button 'Register'

    expect(page.current_url).to match(app_callback_url)
  end
end
