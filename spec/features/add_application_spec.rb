require 'rails_helper'

feature 'Add application to accounts', js: true do
  scenario 'without logging in' do
    visit '/oauth/applications'
    expect_sign_in_page
  end

  scenario 'as an admin user' do
    create_admin_user
    visit '/signin'
    signin_as 'admin'
    expect(page).to have_content('Welcome, admin')
    visit '/oauth/applications'
    expect(page).to have_content('OAuth Applications')
    create_new_application(true)
    expect(page).to have_content('Application created.')
    expect(page).to have_content('Application: example')
    expect(page).to have_content('Callback urls: https://localhost/')
    expect(page.text).to match(/Application Id: [a-z0-9]+/)
    expect(page.text).to match(/Secret: [a-z0-9]+/)
    expect(page).to have_content('Trusted? Yes')
  end

  scenario 'as a normal local user' do
    create_user 'user'
    visit '/signin'
    signin_as 'user'

    visit '/oauth/applications/new'
    expect(page).to have_http_status 403
  end
end
