require 'rails_helper'

feature 'Add social auth', js: true do
  let(:user_1_email){ 'user1@example.com' }
  let(:user_2_email) { 'user2@example.com' }
  let(:user_1) { create_user(user_1_email) }
  let(:user_2) { create_user(user_2_email) }

  scenario "email collides with a different existing user's verified email" do
    mock_current_user(user_1)

    click_link(I18n.t :'users.edit.enable_other_sign_in_options')
    wait_for_animations
    expect(page).to have_content('Facebook')

    with_omniauth_test_mode(email: user_1_email) do
      find('.authentication[data-provider="facebook"] .add--newflow').click
      wait_for_ajax
      expect(page).to have_current_path profile_path
      expect(page).to have_content("already in use")
    end
  end

  scenario "email collides with the current user's verified email" do
    mock_current_user(user_1)

    click_link(I18n.t :'users.edit.enable_other_sign_in_options')
    wait_for_animations
    expect(page).to have_content('Facebook')

    with_omniauth_test_mode(email: user_1_email) do
      find('.authentication[data-provider="facebook"] .add--newflow').click
      wait_for_ajax
      expect(page).to have_current_path profile_path
      expect(page).to have_no_content("already in use")
      expect(page).to have_content('Facebook')
    end
  end

  scenario "email collides with existing user's unverified email" do
    mock_current_user(user_1)

    click_link(I18n.t :'users.edit.enable_other_sign_in_options')
    wait_for_animations
    expect(page).to have_content('Facebook')

    with_omniauth_test_mode(email: user_2_email) do
      find('.authentication[data-provider="facebook"] .add--newflow').click
      wait_for_ajax
      expect(page).to have_current_path profile_path
      expect(page).to have_content('Facebook')
    end
  end
end
