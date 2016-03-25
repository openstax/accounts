require 'rails_helper'

feature 'User manages emails', js: true do
  before(:each) do
    user = create_user('user')
    create_email_address_for(user, 'user@unverified.com',
                             confirmation_code: SecureRandom.hex(32))
    visit '/signin'
    signin_as 'user'
    expect(page).to have_content('Welcome, user')

    visit '/profile'
    expect(page).to have_content('Emails')
  end

  context 'create' do
    scenario 'success' do
      click_link 'Add an email'
      within(:css, '.email-entry.new') {
        find('input').set('user@mysite.com')
        find('.glyphicon-ok').click
      }
      expect(page).to have_content('Click to verify')
      expect(page).to have_content('user@mysite.com')
    end

    scenario 'with empty value' do
      click_link 'Add an email'
      within(:css, '.email-entry.new') {
        find('input').set('')
        find('.glyphicon-ok').click
      }
      # input just disappears
      expect(page).to_not have_css('.email-entry.new input')
    end

    scenario 'with invalid value' do
      click_link 'Add an email'
      within(:css, '.email-entry.new') {
        find('input').set('user')
        find('.glyphicon-ok').click
      }
      expect(page).to have_content('Value "user" is not a valid email address')
    end
  end

  context 'destroy' do
    scenario 'success' do
      within(:css, '.email-entry') {
        find('.email').click
        find('.delete').click
      }
      within(:css, '.popover-content') {
        find('.confirm-dialog-btn-confirm').click
      }
      expect(page).to_not have_content('user@unverified.com')
    end
  end

  context 'resend_confirmation' do
    scenario 'success' do
      click_link 'Click to verify'
      expect(page).to have_content('A verification message has been sent to "')
    end
  end
end
