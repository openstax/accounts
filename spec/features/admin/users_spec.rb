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

        it 'shows the external id in the results' do
          external_id = FactoryBot.create(:external_id, user: @sf_user).external_id

          visit '/admin/users'
          click_button 'Search'

          expect(page).to have_css('td.external-id', text: external_id)
        end

        it "can bring up the edit page without exploding" do
          visit "/admin/users/#{@sf_user.id}/edit"
          expect(page).to have_no_content("We had some unexpected")
        end
      end

      context 'editing self-reported school' do
        it 'picks a suggestion from the autocomplete and links it' do
          FactoryBot.create :school, name: 'Rice University', city: 'Houston', state: 'TX'
          @sf_user.update!(school: nil, self_reported_school: nil)

          visit "/admin/users/#{@sf_user.id}/edit"
          fill_in 'user[self_reported_school]', with: 'Rice'

          expect(page).to have_css('.school-autocomplete-results li', text: 'Rice University')

          find('.school-autocomplete-results li', text: 'Rice University', match: :first).click
          click_button 'Save'

          expect(page).to have_no_content("We had some unexpected")
          expect(find_field('user[self_reported_school]').value).to eq 'Rice University'
          expect(@sf_user.reload.school.name).to eq 'Rice University'
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

    context 'user details page' do
      before(:each) do
        wait_for_successful_log_in
        @target_user = create_user('target_user')
      end

      it 'shows the self-reported "other" role name' do
        @target_user.update_attribute(:other_role_name, 'Curriculum Coordinator')

        visit "/admin/users/#{@target_user.id}/edit"

        expect(page).to have_content('Curriculum Coordinator')
      end

      it 'shows when the user last signed in, including "Never" when they have not' do
        visit "/admin/users/#{@target_user.id}/edit"
        expect(page).to have_content('Never')

        @target_user.update_column(:last_signed_in_at, Time.zone.local(2026, 1, 15, 10, 30))
        visit "/admin/users/#{@target_user.id}/edit"

        expect(page).to have_content('January 15, 2026')
      end

      it 'can remove a linked Salesforce contact with the Remove link control' do
        @target_user.update_attribute(:salesforce_contact_id, 'existingContactId')

        visit "/admin/users/#{@target_user.id}/edit"
        expect(page).to have_content('existingContactId')

        accept_confirm do
          click_button 'Remove link'
        end

        expect(page).to have_current_path("/admin/users/#{@target_user.id}/edit")
        expect(page).to have_content('successfully updated')

        @target_user.reload
        expect(@target_user.salesforce_contact_id).to be_nil
      end
    end
  end
end
