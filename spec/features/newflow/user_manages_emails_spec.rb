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

    scenario 'with invalid email format' do
      click_link_or_button "Add an email"
      within(:css, '.email-entry.new') {
        find('input').set('user')
        find('.glyphicon-ok').click
      }
      expect(page).to have_content(error_msg EmailAddress, :value, :invalid, value: 'user')
    end
  end

  context 'destroy' do
    before(:each) do
      mock_current_user(user)
      visit '/i/profile'
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
