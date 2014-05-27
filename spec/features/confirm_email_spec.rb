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
    expect(page).to have_content("Sorry, we couldn't verify an email using the confirmation code you provided.")
  end

  scenario 'with unmatched confirmation code' do
    visit '/confirm?code=1234'
    expect(page).to have_content("Sorry, we couldn't verify an email using the confirmation code you provided.")
  end
end
