require 'rails_helper'

feature 'User manages emails', js: true do
  let(:verified_emails) { ["one@verified.com"] }
  let(:unverified_emails) { [] }

  let(:user) {
    create_user('user').tap do |user|
      verified_emails.each do |verified_email|
        create_email_address_for(user, verified_email)
      end

      unverified_emails.each do |unverified_email|
        create_email_address_for(user, unverified_email, SecureRandom.hex(32))
      end
    end
  }

  before(:each) do
    mock_current_user(user)
    visit '/profile'
  end

  context 'create' do
    scenario 'success' do
      click_link(t :"users.edit.add_email_address")
      within(:css, '.email-entry.new') {
        find('input').set('user@mysite.com')
        find('.glyphicon-ok').click
      }
      expect(page).to have_no_missing_translations
      expect(page).to have_button(t :"users.edit.click_to_verify")
      expect(page).to have_content('user@mysite.com')
    end

    scenario 'with empty value' do
      click_link (t :"users.edit.add_email_address")
      within(:css, '.email-entry.new') {
        find('input').set('')
        find('.glyphicon-ok').click
      }
      expect(page).to_not have_css('.email-entry.new input')
    end

    scenario 'with invalid value' do
      click_link (t :"users.edit.add_email_address")
      within(:css, '.email-entry.new') {
        find('input').set('user')
        find('.glyphicon-ok').click
      }
      expect(page).to have_content('Value "user" is not a valid email address')
    end
  end

  context 'destroy' do
    context 'when there are two emails' do
      let(:verified_emails) { ['one@verified.com', 'two@verified.com']}

      scenario 'one of the emails can be deleted' do
        email = nil

        within(:css, '.email-entry:first-of-type') {
          email = find('.email').text
          find('.email').click
          find('.delete').click
        }

        within(:css, '.popover-content') {
          find('.confirm-dialog-btn-confirm').click
        }
        expect(page).to_not have_content(email)
      end
    end

    context 'when there is only one email' do
      scenario 'that email cannot be deleted' do
        expect(page).not_to have_selector('.email .delete')
      end
    end
  end

  context 'resend_confirmation' do
    let(:verified_emails) { [] }
    let(:unverified_emails) { ['user@unverified.com'] }

    scenario 'success' do
      click_button (t :"users.edit.click_to_verify")
      expect(page).to have_no_missing_translations
      expect(page).to have_content(t :"controllers.contact_infos.verification_sent", address: "user@unverified.com")
      expect(page).to have_button((t :"users.edit.click_to_verify"), disabled: true)
    end
  end
end
