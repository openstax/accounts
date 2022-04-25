require 'rails_helper'

feature 'Admin user pages' do
  context 'as an admin user' do
    before(:each) do
      @admin_user = create_admin_user
      visit :login
      log_in_user('admin@openstax.org', 'password')
    end

    context "with a user with salesforce contact ID set" do
      before(:each) do
        @sf_user = create_user 'sf_user@openstax.org'
        @sf_user.update_attributes(salesforce_contact_id: "booyah")
      end

      context 'full console' do
        it 'searches users and does not explode' do
          visit '/admin/users'
          click_button 'Search'

          expect(page).to have_no_content("We had some unexpected")

          page.all(:css, '.expand').each(&:click)

          expect(page).to have_content("#{@admin_user.full_name} | Administrator |")
          expect(page).to have_content("#{@sf_user.full_name} | Salesforce: booyah")
        end

        it "can bring up the edit page without exploding" do
          visit "/admin/users/#{@sf_user.id}/edit"
          expect(page).to have_no_content("We had some unexpected")
        end
      end
    end
  end
end
