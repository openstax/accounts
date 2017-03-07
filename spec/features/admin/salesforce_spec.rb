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
      expect(page).not_to have_content("We had some unexpected")
    end
  end
end
