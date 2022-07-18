require 'rails_helper'

feature 'Admin oauth app create and edit', js: true do
  context 'as an admin user' do
    before(:each) do
      @admin_user = create_admin_user
      visit '/'
      log_in('admin', 'password')
    end

    it 'can create and edit applications' do
      visit '/oauth/applications'
      click_link 'New'
      fill_in 'Name', with: 'Test'
      fill_in 'Redirect URI', with: 'urn:ietf:wg:oauth:2.0:oob'
      fill_in 'Email subject prefix', with: '[Test]'
      fill_in 'Lead application source', with: 'Tutor Signup'
      fill_in 'Email from address', with: 'blah@example.com'
      click_button 'Submit'

      expect(page).to have_content("Tutor Signup")

      click_link 'Edit'

      fill_in 'Lead application source', with: 'App Source Blah'

      click_button 'Submit'

      expect(page).to have_content("App Source Blah")
    end
  end
end
