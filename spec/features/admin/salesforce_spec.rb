require 'rails_helper'

feature 'Admin salesforce pages', js: true do
  context 'as an admin user' do
    before(:each) do
      @admin_user = create_admin_user
      visit '/'
      complete_login_username_or_email_screen('admin')
      complete_login_password_screen('password')
    end

    it 'can visit the actions page' do
      visit '/admin/salesforce/actions'
      expect(page).to have_no_content("We had some unexpected")
    end

    it 'can trigger a user info update' do
      visit '/admin/salesforce/actions'
      expect(UpdateUserSalesforceInfo).to receive(:call)
      click_button 'Refresh'
      expect(page).to have_no_content("We had some unexpected")
      expect(page).to have_content("Refresh Salesforce User Info")
    end
  end
end
