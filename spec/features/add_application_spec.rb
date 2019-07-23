require 'rails_helper'

feature 'Add application to accounts', js: true do
  scenario 'without logging in' do
    visit '/oauth/applications'
    expect_sign_in_page
  end

  scenario 'as an admin user' do
    create_admin_user
    visit '/'
    complete_login_username_or_email_screen('admin')
    complete_login_password_screen('password')

    visit '/oauth/applications'
    expect(page).to have_content('OAuth2 Provider')
    create_new_application(true)
    expect(page).to have_content('Application created.')
    expect(page).to have_content('Application: example')
    expect(page).to have_content('Callback urls: https://localhost/')
    expect(page.text).to match(/Application UID: [a-z0-9]+/)
    expect(page.text).to match(/Secret: [a-z0-9]+/)
    expect(page).to have_content('Trusted? Yes')
  end
end
