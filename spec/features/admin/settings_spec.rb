require 'rails_helper'

feature 'Admin settings page', js: true do
  context 'as an admin user' do
    before(:each) do
      create_admin_user
      visit '/'
      log_in('admin', 'password')
    end

    it 'is well formed' do
      OpenStax::RescueFrom.do_reraise do
        visit '/admin/settings'
      end

      expect(page).to have_content("Push leads to Salesforce?")
    end

  end
end
