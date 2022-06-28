require 'rails_helper'

feature 'Add social auth', js: true do
  let(:email_value){ 'user@example.com' }
  let(:other_user_email){ 'other_user@example.com' }

  scenario "email collides with a different existing user's verified email" do
    user = create_user(email_value)
    user.update(role: :student)
    log_in_user(email_value, 'password')

    expect_profile_page

    click_link (t :"users.edit.enable_other_sign_in_options")
    wait_for_animations
    expect(page).to have_content('Facebook')

    with_omniauth_test_mode(email: email_value) do
      find('.authentication[data-provider="facebooknewflow"] .add--newflow').click
      wait_for_ajax
      screenshot!
      expect_profile_page
      expect(page).to have_content("already in use")
    end
  end

  scenario "email collides with the current user's verified email" do
    user = create_user email_value
    user.update(role: :student)

    log_in_user(email_value, 'password')

    expect_profile_page

    click_link (t :"users.edit.enable_other_sign_in_options")
    wait_for_animations
    expect(page).to have_content('Facebook')

    with_omniauth_test_mode(email: email_value) do
      find('.authentication[data-provider="facebooknewflow"] .add--newflow').click
      wait_for_ajax
      expect_profile_page
      expect(page).to have_no_content("already in use")
      expect(page).to have_content('Facebook')
    end
  end

  scenario "email collides with existing user's UNverified email" do
    create_email_address_for(create_user(other_user_email), email_value, 'token')

    user = create_user email_value
    user.update(role: :student)
    log_in_user(email_value, 'password')

    expect_profile_page

    click_link (t :"users.edit.enable_other_sign_in_options")
    wait_for_animations
    expect(page).to have_content('Facebook')

    with_omniauth_test_mode(email: email_value) do
      find('.authentication[data-provider="facebooknewflow"] .add--newflow').click
      wait_for_ajax
      screenshot!
      expect_profile_page
      expect(page).to have_content('Facebook')
    end
  end
end
