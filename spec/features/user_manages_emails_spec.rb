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

  context 'create' do
    before(:each) do
      mock_current_user(user)
      visit '/profile'
    end

    scenario 'success' do
      click_link(t :"users.edit.add_email_address")
      within(:css, '.email-entry.new') {
        find('input').set('user@mysite.com')
        find('.glyphicon-ok').click
        wait_for_ajax
        find(".unconfirmed-warning").click
      }
      expect(page).to have_no_missing_translations
      expect(page).to have_button(t :"users.edit.resend_confirmation")
      expect(page).to have_content('user@mysite.com')
    end

    scenario 'click to verify does not change token' do
      click_link(t :"users.edit.add_email_address")
      within(:css, '.email-entry.new') {
        find('input').set('user@mysite.com')
        find('.glyphicon-ok').click
      }
      wait_for_ajax
      open_email('user@mysite.com')
      original_link_path = get_path_from_absolute_link(current_email, 'a')

      expect(page).to have_no_missing_translations
      within all(".email-entry").last do
        find(".unconfirmed-warning").click
        expect(page).to have_button(t :"users.edit.resend_confirmation")
        click_button(t :"users.edit.resend_confirmation")
      end
      visit(original_link_path)
      expect(page).to have_content(t :"contact_infos.confirm.page_heading.success")
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

    scenario 'toggles searchable field' do
      expect(page).to_not have_content(t('users.edit.searchable'))
      find(".email-entry[data-id=\"#{user.id}\"] .email").click
      expect(page).to have_content(t('users.edit.searchable'))
      screenshot!
    end

  end

  # TODO screenshots all around
  # TODO spec to show can't add already-used email

  context 'destroy' do
    before(:each) do
      mock_current_user(user)
      visit '/profile'
    end

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
        expect(page).to have_selector('.email')
        expect(page).not_to have_selector('.email .delete')
      end
    end

    context 'when there is only one email' do
      scenario 'that email cannot be deleted' do
        expect(page).not_to have_selector('.email .delete')
      end
    end
  end

  context 'resend_confirmation' do
    before(:each) do
      mock_current_user(user)
      visit '/profile'
    end

    let(:verified_emails) { [] }
    let(:unverified_emails) { ['user@unverified.com'] }

    scenario 'success' do
      find(".email-entry[data-id=\"#{user.id}\"] .value").click
      click_button (t :"users.edit.resend_confirmation")
      expect(page).to have_no_missing_translations
      expect(page).to have_content(t :"controllers.contact_infos.verification_sent", address: "user@unverified.com")
      expect(page).to have_button((t :"users.edit.resend_confirmation"), disabled: true)
    end
  end

  scenario 'confirmation does not log user in' do
    create_email_address_for(user, 'yoyo@yoyo.com', 'atoken')
    visit '/profile'
    expect_sign_in_page
    visit(confirm_path(code: 'atoken'))
    expect(page).to have_content(t :"contact_infos.confirm.page_heading.success")
    visit('/profile')
    expect_sign_in_page
  end
end
