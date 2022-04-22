require 'rails_helper'

feature 'Add social auth', js: true do
  let(:user_1_email){ 'user1@example.com' }
  let(:user_2_email) { 'user2@example.com' }
  let(:user_1) { create_user(user_1_email) }
  let(:user_2) { create_user(user_2_email) }

  scenario "email collides with a different existing user's verified email" do
    user_1.update(role: :student)
    log_in_user(user_1_email, 'password')

    expect_profile_page

    click_link (I18n.t :'users.edit.enable_other_sign_in_options')
    wait_for_animations
    expect(page).to have_content('Facebook')

    with_omniauth_test_mode(email: user_1_email) do
      find('.authentication[data-provider="facebook"] .add--newflow').click
      wait_for_ajax
      screenshot!
      expect_profile_page
      expect(page).to have_content("already in use")
    end
  end

  scenario "email collides with the current user's verified email" do
    user_1.update(role: :student)
    log_in_user(user_1_email, 'password')

    expect_profile_page

    click_link (t :'users.edit.enable_other_sign_in_options')
    wait_for_animations
    expect(page).to have_content('Facebook')

    with_omniauth_test_mode(email: user_1_email) do
      find('.authentication[data-provider="facebook"] .add--newflow').click
      wait_for_ajax
      expect_profile_page
      expect(page).to have_no_content("already in use")
      expect(page).to have_content('Facebook')
    end
  end

  scenario "email collides with existing user's UNverified email" do
    user_1.update(role: :student)
    log_in_user(user_1_email, 'password')

    expect_profile_page

    click_link (I18n.t :'users.edit.enable_other_sign_in_options')
    wait_for_animations
    expect(page).to have_content('Facebook')

    with_omniauth_test_mode(email: user_2_email) do
      find('.authentication[data-provider="facebook"] .add--newflow').click
      wait_for_ajax
      screenshot!
      expect_profile_page
      expect(page).to have_content('Facebook')
    end
  end
end
