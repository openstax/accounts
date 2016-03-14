require 'rails_helper'

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
      fill_in 'Add an email address', with: 'user@mysite.com'
      click_button 'Add'
      expect(page).to have_content('Change Your Password')
      expect(page).to have_content(
        'A verification message has been sent to "user@mysite.com"')
      expect(page).to have_content('user@mysite.com')
    end

    scenario 'with empty value', js: true do
      fill_in 'Add an email address', with: ''
      click_button 'Add'
      expect(page).to have_content("Value can't be blank")
    end

    scenario 'with invalid value', js: true do
      fill_in 'Add an email address', with: 'user'
      click_button 'Add'
      expect(page).to have_content('Value "user" is not a valid email address')
    end
  end

  context 'destroy' do
    scenario 'success', js: true do
      click_link 'Delete'
      expect(page).to have_content('Email address deleted')
    end
  end

  context 'resend_confirmation' do
    scenario 'success', js: true do
      click_link 'Click to verify'
      expect(page).to have_content('A verification message has been sent to "')
    end
  end
end
