require 'rails_helper'

feature 'User manages emails', js: true do
  let(:verified_emails) { ["one@verified.com"] }
  let(:unverified_emails) { [] }
  let(:invalid_provider_email) {
    "invalidMX#{SecureRandom.hex(3)}.com"
  }
  let(:blacklisted_provider_email) {
    EmailDomain.create!(value: "noMX#{SecureRandom.hex(3)}.com", has_mx: false).value
  }

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
      visit '/i/profile'
    end

    # scenario 'success' do
    #   click_link(find('#add-an-email'))
    #   find('input').set('user@mysite.com')
    #   find('.glyphicon-ok').click
    #   wait_for_ajax
    #   find(".unconfirmed-warning").click
    #
    #   capture_email!(address: 'user@mysite.com')
    #   expect(page).to have_no_missing_translations
    #   expect(page).to have_button(I18n.t(:"users.edit.resend_confirmation"))
    #   expect(page).to have_content('user@mysite.com')
    # end

    scenario 'click to verify does not change token' do
      click_link(I18n.t(:"users.edit.add_email_address"))
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
        expect(page).to have_button(I18n.t(:"users.edit.resend_confirmation"))
        click_button(I18n.t(:"users.edit.resend_confirmation"))
      end
      visit(original_link_path)
      expect(page).to have_content(t :"contact_infos.confirm.page_heading.success")
    end

    scenario 'with empty value' do
      click_link(I18n.t(:"users.edit.add_email_address"))
      within(:css, '.email-entry.new') {
        find('input').set('')
        find('.glyphicon-ok').click
      }
      expect(page).to have_no_css('.email-entry.new input')
    end

    scenario 'with invalid email format' do
      click_link(I18n.t(:"users.edit.add_email_address"))
      within(:css, '.email-entry.new') {
        find('input').set('user')
        find('.glyphicon-ok').click
      }
      expect(page).to have_content(error_msg EmailAddress, :value, :invalid, value: 'user')
    end

    scenario 'with invalid email provider' do
      email_address = "goodformat@#{invalid_provider_email}"
      # makes a real DNS/HTTP request
      EmailDomainMxValidator.strategy = EmailDomainMxValidator::DnsStrategy.new

      click_link(I18n.t(:"users.edit.add_email_address"))
      within(:css, '.email-entry.new') {
        find('input').set(email_address)
        find('.glyphicon-ok').click
        wait_for_ajax
      }
      expect(page).to have_content(error_msg EmailAddress, :value, :missing_mx_records, value: email_address)
    end

    scenario 'with valid email provider' do
      email_address = 'anyone@openstax.org'
      # makes a real DNS/HTTP request
      EmailDomainMxValidator.strategy = EmailDomainMxValidator::DnsStrategy.new

      click_link(I18n.t(:"users.edit.add_email_address"))
      within(:css, '.email-entry.new') {
        find('input').set(email_address)
        find('.glyphicon-ok').click
        wait_for_ajax
        find(".unconfirmed-warning").click
      }
      capture_email!(address: 'anyone@openstax.org')
      expect(page).to have_no_missing_translations
      expect(page).to have_button(I18n.t(:"users.edit.resend_confirmation"))
      expect(page).to have_content('anyone@openstax.org')
    end

    # scenario 'toggles searchable field' do
    #   expect(page).to have_no_content(t(:".searchable"))
    #   find(".email-entry[data-id=\"#{user.id}\"] .email").click
    #   expect(page).to have_content(t(:".searchable"))
    #   screenshot!
    # end

  end

  # TODO screenshots all around
  # TODO spec to show can't add already-used email

  context 'destroy' do
    before(:each) do
      mock_current_user(user)
      visit '/i/profile'
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
        expect(page).to have_no_content(email)
        expect(page).to have_selector('.email')
        expect(page).to have_no_selector('.email .delete')
      end
    end

    context 'when there is only one email' do
      scenario 'that email cannot be deleted' do
        expect(page).to have_no_selector('.email .delete')
      end
    end
  end

  context 'resend_confirmation' do
    before(:each) do
      mock_current_user(user)
      visit '/i/profile'
    end

    let(:verified_emails) { [] }
    let(:unverified_emails) { ['user@unverified.com'] }

    # scenario 'success' do
    #   find(".email-entry[data-id=\"#{user.id}\"] .value").click
    #   click_button (I18n.t(:"users.edit.resend_confirmation"))
    #   expect(page).to have_no_missing_translations
    #   expect(page).to have_content(t :"controllers.contact_infos.verification_sent", address: "user@unverified.com")
    #   expect(page).to have_button((I18n.t(:".resend_confirmation")), disabled: true)
    # end
  end

  scenario 'confirmation does not log user in' do
    create_email_address_for(user, 'yoyo@yoyo.com', 'atoken')
    visit '/i/profile'
    expect_sign_in_page
    visit(confirm_path(code: 'atoken'))
    expect(page).to have_content(t :"contact_infos.confirm.page_heading.success")
    visit('/i/profile')
    expect_sign_in_page
  end
end
