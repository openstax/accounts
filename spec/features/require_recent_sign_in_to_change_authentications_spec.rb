require 'rails_helper'

xfeature 'Require recent sign in to change authentications', js: true do

  scenario 'adding a new authentication' do
    user = create_user 'user'

    visit '/signin'
    expect_sign_in_page
    signin_as 'user'
    expect(page).to have_http_status :ok
    expect(page).to have_content('Welcome, user')

    Timecop.freeze(Time.now + RequireRecentSignin::REAUTHENTICATE_AFTER) do
      visit '/profile'
      expect_profile_page
      expect(page).not_to have_content('Facebook')

      click_link 'Enable other sign in options'
      wait_for_animations
      expect(page).to have_no_content('Enable other sign in options')
      expect(page).to have_content('Other sign in options')
      expect(page).to have_content('Facebook')

      with_omniauth_test_mode(identity_user: user) do
        find('.authentication[data-provider="facebook"] .add').click
        wait_for_ajax
        expect_sign_in_page
        expect(page).to have_content('Please sign in again to confirm your changes')

        signin_as 'user'
        expect_profile_page
        expect(page).to have_content('Facebook')
      end
    end
  end

  scenario 'changing the password' do
    with_forgery_protection do
      create_user 'user'

      visit '/signin'
      expect_sign_in_page
      signin_as 'user'
      expect(page).to have_no_missing_translations
      expect(page).to have_content(t :"layouts.application_header.welcome_html", username: 'user')

      Timecop.freeze(Time.now + RequireRecentSignin::REAUTHENTICATE_AFTER) do
        visit '/profile'
        expect_profile_page

        find('.authentication[data-provider="identity"] .edit').click
        fill_in 'password', with: 'password'
        fill_in 'password_confirmation', with: 'password'
        find('.authentication.editing[data-provider="identity"] button[type="submit"]').click
        expect_sign_in_page
        expect(page).to have_content(t :"controllers.authentications.please_sign_in_to_confirm_changes")

        signin_as 'user'
        expect_profile_page

        find('.authentication[data-provider="identity"] .edit').click
        fill_in 'password', with: 'password'
        fill_in 'password_confirmation', with: 'password'
        find('.authentication.editing[data-provider="identity"] button[type="submit"]').click
        expect(page).to have_content(t :"controllers.identities.password_changed")
      end
    end
  end

  scenario 'removing an authentication' do
    with_forgery_protection do
      user = create_user 'user'
      FactoryGirl.create :authentication, user: user, provider: 'twitter'

      visit '/signin'
      expect_sign_in_page
      signin_as 'user'
      expect(page).to have_no_missing_translations
      expect(page).to have_content(t :"layouts.application_header.welcome_html", username: 'user')

      Timecop.freeze(Time.now + RequireRecentSignin::REAUTHENTICATE_AFTER) do
        visit '/profile'
        expect_profile_page
        expect(page).to have_content('Twitter')

        find('.authentication[data-provider="twitter"] .delete').click
        click_button 'OK'
        expect_sign_in_page
        expect(page).to have_content(t :"controllers.authentications.please_sign_in_to_confirm_changes")

        signin_as 'user'
        expect_profile_page

        find('.authentication[data-provider="twitter"] .delete').click
        click_button 'OK'
        expect(page).not_to have_content('Twitter')
      end
    end
  end

end
