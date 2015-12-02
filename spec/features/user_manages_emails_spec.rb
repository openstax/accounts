require 'spec_helper'

feature 'User manages emails' do
  before(:each) do
    user = create_user('user')
    create_email_address_for(user, 'user@unverified.com',
                             confirmation_code: SecureRandom.hex(32))
    visit '/login'
    login_as 'user'
    expect(page).to have_content('Welcome, user')

    visit '/profile'
    expect(page).to have_content('Manage Email Addresses')
    click_link 'Manage Email Addresses'
  end

  context 'create' do
    scenario 'success', js: true do
      fill_in 'Email address', with: 'user@mysite.com'
      click_button 'Add Email address'
      expect(page).to have_content(
        'A verification message has been sent to "user@mysite.com"')
      expect(page).to have_content('user@mysite.com')
    end

    scenario 'with empty value', js: true do
      fill_in 'Email address', with: ''
      click_button 'Add Email address'
      expect(page).to have_content("Value can't be blank")
    end

    scenario 'with invalid value', js: true do
      fill_in 'Email address', with: 'user'
      click_button 'Add Email address'
      expect(page).to have_content('Value is invalid')
    end
  end

  context 'destroy' do
    scenario 'success', js: true do
      click_button 'Delete'
      expect(page).to have_content('Email address deleted')
    end
  end

  context 'resend_confirmation' do
    scenario 'success', js: true do
      click_button 'Resend Verification'
      expect(page).to have_content('A verification message has been sent to "')
    end
  end
end
