require 'rails_helper'

feature 'Non-admins cannot reach admin console', js: true do
  context 'as an admin user' do
    before(:each) do
      @user = create_user 'user'
      visit '/'
      complete_login_username_or_email_screen('user')
      complete_login_password_screen('password')
    end

    it 'cannot visit the console' do
      visit '/admin/console'
      expect(page).to have_content("(403)")
    end

    it 'cannot visit the salesforce settings' do
      visit '/admin/salesforce'
      expect(page).to have_content("(403)")
    end
  end
end
