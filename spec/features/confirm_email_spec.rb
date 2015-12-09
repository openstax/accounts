require 'spec_helper'

feature 'Confirm email address', js: true do
  background do
    user = create_user 'user'
    create_email_address_for user, 'user@example.com', '1111'
  end

  scenario 'successfully' do
    visit '/confirm?code=1111'
    expect(page).to have_content('Thank you for verifying your email address')
    expect(page).to have_content('Thanks for adding your email address.')
  end

  scenario 'without a confirmation code' do
    visit '/confirm'
    expect(page).to have_content("Sorry, we couldn't verify an email using the verification code you provided.")
  end

  scenario 'with unmatched confirmation code' do
    visit '/confirm?code=1234'
    expect(page).to have_content("Sorry, we couldn't verify an email using the verification code you provided.")
  end

  scenario 'successfully during registration' do
    # set the user state to "temp" so we can test registration
    user = create_user 'user2'
    user.state = 'temp'
    user.save

    visit '/'
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
    expect(page).to have_content(
      'Please close this tab and continue your registration process in OpenStax')
  end
end
