require 'rails_helper'

feature 'Create banners', js: true do
  context 'as an admin user' do
    before(:each) do
      @admin_user = create_admin_user
      visit '/'
      complete_login_username_or_email_screen('admin')
      complete_login_password_screen('password')
    end

    it 'can visit the banners page' do
      visit '/admin/banners'
      expect(page).not_to have_content("We had some unexpected")
    end

    it 'displays same time (therefore in the same timezone) that it was assigned' do
      visit '/admin/banners/new'
      fill_in 'banner[message]', with: 'whatever'
      select "#{Time.current.year + 1}", from: 'banner[expires_at(1i)]'
      select '05 PM', from: 'banner[expires_at(4i)]'
      click_button 'Create'
      expect(page).to have_content('05:00PM')
    end
  end
end
