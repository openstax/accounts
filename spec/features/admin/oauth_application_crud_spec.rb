require 'rails_helper'

feature 'Admin oauth app create and edit', js: true do
  context 'as an admin user' do
    before(:each) do
      @admin_user = create_admin_user
      visit '/'
      log_in('admin@openstax.org')
    end

    it 'can create and edit applications' do
      visit '/oauth/applications/new'
      fill_in 'Name', with: 'Test'
      fill_in 'Redirect URI', with: 'urn:ietf:wg:oauth:2.0:oob'
      fill_in 'Email subject prefix', with: '[Test]'
      fill_in 'Email from address', with: 'blah@example.com'
      click_button 'Submit'

      expect(page).to have_content("Application: Test")

      click_link 'Edit'

      fill_in 'Name', with: 'New App Name'

      click_button 'Submit'

      expect(page).to have_content("Application: New App Name")
    end
  end
end
