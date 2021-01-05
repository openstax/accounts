require 'rails_helper'

feature 'Add social auth', js: true do
  scenario "email collides with a different existing user's verified email" do
    create_email_address_for(create_user('other_user'), 'user@example.com')

    user = create_user 'user'
    log_in('user', 'password')

    expect_profile_page

    click_link (t :"legacy.users.edit.enable_other_sign_in_options")
    wait_for_animations
    expect(page).to have_content('Facebook')

    with_omniauth_test_mode(email: 'user@example.com') do
      find('.authentication[data-provider="facebook"] .add').click
      wait_for_ajax
      screenshot!
      expect_profile_page
      expect(page).to have_content("already in use")
    end
  end

  scenario "email collides with the current user's verified email" do
    user = create_user 'user'
    create_email_address_for(user, 'user@example.com')

    log_in('user', 'password')

    expect_profile_page

    click_link (t :"legacy.users.edit.enable_other_sign_in_options")
    wait_for_animations
    expect(page).to have_content('Facebook')

    with_omniauth_test_mode(email: 'user@example.com') do
      find('.authentication[data-provider="facebook"] .add').click
      wait_for_ajax
      expect_profile_page
      expect(page).to have_no_content("already in use")
      expect(page).to have_content('Facebook')
    end
  end

  scenario "email collides with existing user's UNverified email" do
    create_email_address_for(create_user('other_user'), 'user@example.com', 'token')

    user = create_user 'user'
    log_in('user', 'password')

    expect_profile_page

    click_link (t :"legacy.users.edit.enable_other_sign_in_options")
    wait_for_animations
    expect(page).to have_content('Facebook')

    with_omniauth_test_mode(email: 'user@example.com') do
      find('.authentication[data-provider="facebook"] .add').click
      wait_for_ajax
      screenshot!
      expect(page).to have_content('already been taken')
      expect(page).not_to have_content('Facebook')
    end
  end

end
