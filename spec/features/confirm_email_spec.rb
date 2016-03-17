require 'rails_helper'

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
    expect(page).to_not have_content('Alert: no_contact_info_for_code')
    expect(page).to have_content('Alert: Unable to verify email address')
    expect(page).to have_content("Sorry, we couldn't verify an email using the verification code you provided.")
  end

  scenario 'with unmatched confirmation code' do
    visit '/confirm?code=1234'
    expect(page).to_not have_content('Alert: no_contact_info_for_code')
    expect(page).to have_content('Alert: Unable to verify email address')
    expect(page).to have_content("Sorry, we couldn't verify an email using the verification code you provided.")
  end
end
