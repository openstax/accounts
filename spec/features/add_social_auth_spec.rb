require 'rails_helper'

xfeature 'Add social auth', js: true do
  before do
    load('db/seeds.rb')
  end

  let(:email_value) { 'user@example.com' }
  let(:user) { create_user email_value }
  let(:name_value) { 'Elon Musk' }

  context 'email collisions' do
    scenario "email collides with a different existing user's verified email" do
      create_user('other_user@example.com')
      mock_current_user(user)

      visit(profile_path)
      expect_profile_page

      click_link(t :"users.edit.enable_other_sign_in_options")
      wait_for_animations
      expect(page).to have_content('Facebook')

      simulate_login_signup_with_social(name: name_value, email: email_value) do
        find('.authentication[data-provider="facebook"] .add').click
        wait_for_ajax
        screenshot!
        reauthenticate_user(email_value, 'password')
        expect(page).to_not have_content("Facebook")
      end
    end

    scenario "email collides with the current user's verified email" do
      create_user('other_user2@example.com')
      mock_current_user(user)

      visit(profile_path)
      expect_profile_page

      click_link(t :"users.edit.enable_other_sign_in_options")
      expect(page).to have_content('Facebook')

      simulate_login_signup_with_social(name: name_value, email: email_value) do
        find('.authentication[data-provider="facebook"] .add').click
        wait_for_animations
        wait_for_ajax
        reauthenticate_user(email_value, 'password')
        expect(page).to have_no_content("already in use")
      end
    end

    scenario "email collides with existing user's UNverified email" do
      create_email_address_for(create_user('other_user@example.com'), 'other_user3@example.com', 'token')
      mock_current_user(user)

      visit(profile_path)
      expect_profile_page

      click_link(t :"users.edit.enable_other_sign_in_options")
      expect(page).to have_content('Facebook')

      simulate_login_signup_with_social(name: name_value, email: email_value) do
        find('.authentication[data-provider="facebook"] .add').click
        wait_for_animations
        wait_for_ajax
        reauthenticate_user(email_value, 'password')
        expect(page).to_not have_content('Facebook')
      end
    end
  end
end
