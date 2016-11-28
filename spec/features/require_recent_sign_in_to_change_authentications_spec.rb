require 'rails_helper'

feature 'Require recent sign in to change authentications', js: true do

  scenario 'adding a new authentication' do
    user = create_user 'user'

    log_in('user', 'password')

    expect_profile_page

    Timecop.freeze(Time.now + RequireRecentSignin::REAUTHENTICATE_AFTER) do
      expect(page).not_to have_content('Facebook')

      click_link 'Enable other sign in options'
      wait_for_animations
      expect(page).to have_no_content('Enable other sign in options')
      expect(page).to have_content('Other sign in options')
      expect(page).to have_content('Facebook')

      with_omniauth_test_mode(identity_user: user) do
        find('.authentication[data-provider="facebook"] .add').click
        wait_for_ajax
        expect(page).to have_content(t :"controllers.authentications.please_log_in_again")
        complete_login_password_screen('password')
        expect_profile_page
        expect(page).to have_content('Facebook')
      end
    end
  end

  scenario 'changing the password' do
    with_forgery_protection do
      create_user 'user'

      log_in('user', 'password')

      expect(page).to have_no_missing_translations

      Timecop.freeze(Time.now + RequireRecentSignin::REAUTHENTICATE_AFTER) do
        visit '/profile'
        expect_profile_page

        find('.authentication[data-provider="identity"] .edit').click

        expect(page).to have_content(t :"controllers.authentications.please_log_in_again")
        complete_login_password_screen('password')

        complete_reset_password_screen
        complete_reset_password_success_screen

        expect_profile_page

        find('.authentication[data-provider="identity"] .edit').click

        # Don't have to reauthenticate since just did
        expect(page).not_to have_content(t :"controllers.authentications.please_log_in_again")

        complete_reset_password_screen
        complete_reset_password_success_screen
      end
    end
  end

  scenario 'removing an authentication' do
    with_forgery_protection do
      user = create_user 'user'
      FactoryGirl.create :authentication, user: user, provider: 'twitter'

      log_in('user', 'password')

      expect(page).to have_no_missing_translations

      Timecop.freeze(Time.now + RequireRecentSignin::REAUTHENTICATE_AFTER) do
        visit '/profile'
        expect_profile_page
        expect(page).to have_content('Twitter')

        find('.authentication[data-provider="twitter"] .delete').click
        click_button 'OK'
        expect(page).to have_content(t :"controllers.authentications.please_log_in_again")

        complete_login_password_screen('password')
        expect_profile_page

        find('.authentication[data-provider="twitter"] .delete').click
        click_button 'OK'
        expect(page).not_to have_content('Twitter')
      end
    end
  end

end
