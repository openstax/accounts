require 'rails_helper'

feature 'Admin user pages', js: true do
  context 'as an admin user' do
    before(:each) do
      @admin_user = create_admin_user
      visit '/'
      complete_newflow_log_in_screen('admin', 'password')
    end

    context "with a user with salesforce contact ID set" do
      before(:each) do
        @sf_user = create_user 'sf_user'
        @sf_user.update_attribute(:salesforce_contact_id, "booyah")
      end

      context 'full console' do
        it 'searches users and does not explode' do
          visit '/admin/users'
          click_button 'Search'

          expect(page).to have_no_content("We had some unexpected")

          page.all(:css, '.expand').each(&:click)

          expect(page).to have_content("Administrator |")
        end

        it "can bring up the edit page without exploding" do
          visit "/admin/users/#{@sf_user.id}/edit"
          expect(page).to have_no_content("We had some unexpected")
        end
      end

      context 'popup console' do
        it 'searches users and does not explode' do
          Capybara.current_session.current_window.resize_to 1200, 1200
          visit '/'
          click_link 'Popup Console'
          wait_for_ajax(10) # for some reason this is slow
          click_link 'Users'
          click_button 'Search'

          expect(page).to have_no_content("We had some unexpected")

          page.all(:css, '.expand').each(&:click)

          expect(page).to have_content("#{@admin_user.full_name} Yes No Sign in as | Edit")
          expect(page).to have_content("#{@sf_user.full_name} No No Sign in as | Edit")
        end
      end
    end
  end
end
