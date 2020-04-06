require 'rails_helper'

feature 'Add social auth', js: true do
  before do
    turn_on_student_feature_flag
  end

  scenario "email collides with a different existing user's verified email" do
    create_email_address_for(create_user('other_user'), 'user@example.com')

    user = create_user 'user'
    newflow_log_in_user('user', 'password')

    expect_newflow_profile_page

    click_link (t :"users.edit.enable_other_sign_in_options")
    wait_for_animations
    expect(page).to have_content('Facebook')

    with_omniauth_test_mode(email: 'user@example.com') do
      find('.authentication[data-provider="facebooknewflow"] .add--newflow').click
      wait_for_ajax
      screenshot!
      expect_newflow_profile_page
      expect(page).to have_content("already in use")
    end
  end

  scenario "email collides with the current user's verified email" do
    user = create_user 'user'
    create_email_address_for(user, 'user@example.com')

    newflow_log_in_user('user', 'password')

    expect_newflow_profile_page

    click_link (t :"users.edit.enable_other_sign_in_options")
    wait_for_animations
    expect(page).to have_content('Facebook')

    with_omniauth_test_mode(email: 'user@example.com') do
      find('.authentication[data-provider="facebooknewflow"] .add--newflow').click
      wait_for_ajax
      expect_newflow_profile_page
      expect(page).to have_no_content("already in use")
      expect(page).to have_content('Facebook')
    end
  end

  scenario "email collides with existing user's UNverified email" do
    create_email_address_for(create_user('other_user'), 'user@example.com', 'token')

    user = create_user 'user'
    newflow_log_in_user('user', 'password')

    expect_newflow_profile_page

    click_link (t :"users.edit.enable_other_sign_in_options")
    wait_for_animations
    expect(page).to have_content('Facebook')

    with_omniauth_test_mode(email: 'user@example.com') do
      find('.authentication[data-provider="facebooknewflow"] .add--newflow').click
      wait_for_ajax
      screenshot!
      expect_newflow_profile_page
      expect(page).to have_content('Facebook')
    end
  end

end
