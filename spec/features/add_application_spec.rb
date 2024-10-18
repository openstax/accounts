require 'rails_helper'

feature 'Add application to accounts', js: true do
  scenario 'without logging in' do
    visit '/oauth/applications'
    expect_sign_in_page
  end

  # scenario 'as an admin user' do
  #   create_admin_user
  #   visit '/'
  #   complete_newflow_log_in_screen('admin')
  #
  #   visit '/oauth/applications'
  #   expect(page).to have_content('OAuth2 Provider')
  #   create_new_application(true)
  #   expect(page.current_path).to match('/oauth/applications/')
  #   expect(page).to have_content('Application created.')
  #   expect(page).to have_content('Application: example')
  #   expect(page).to have_content('Callback urls: https://localhost/')
  #   expect(page.text).to match(/Application UID:\n\w+/)
  #   expect(page.text).to match(/Secret:\n\w+/)
  #   expect(page).to have_content('Can access private user data? Yes')
  # end
end
