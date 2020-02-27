require 'rails_helper'

feature 'Require recent log in to change authentications', js: true do
  before do
    turn_on_feature_flag
  end

  scenario 'adding Facebook' do
    user = create_newflow_user 'user@example.com'
    visit '/'
    newflow_log_in_user('user@example.com', 'password')

    expect(page.current_path).to eq(profile_newflow_path)

    Timecop.freeze(Time.now + RequireRecentSignin::REAUTHENTICATE_AFTER) do
      expect(page).to have_no_content('Facebook')
      screenshot!
      click_link (t :"users.edit.enable_other_sign_in_options")
      wait_for_animations
      screenshot!
      expect(page).to have_no_content(t :"users.edit.enable_other_sign_in_options")
      expect(page).to have_content((t :"users.edit.other_sign_in_options_html")[0..7])
      expect(page).to have_content('Facebook')

      with_omniauth_test_mode(identity_user: user) do
        find('.authentication[data-provider="facebooknewflow"] .add--newflow').click
        wait_for_ajax
        expect(page).to have_content(t :"login_signup_form.login_page_header")
        screenshot!
        fill_in(t(:"login_signup_form.password_label"), with: 'password')
        find('[type=submit]').click
        expect(page.current_path).to eq(profile_newflow_path)
        expect(page).to have_content('Facebook')
        screenshot!
      end
    end
  end

  scenario 'changing the password' do
    with_forgery_protection do
      create_newflow_user 'user@example.com'
      visit '/'
      newflow_log_in_user('user@example.com', 'password')
      expect(page).to have_no_missing_translations

      Timecop.freeze(Time.now + RequireRecentSignin::REAUTHENTICATE_AFTER) do
        visit profile_newflow_path

        screenshot!
        find('.authentication[data-provider="identity"] .edit--newflow').click

        expect(page.current_path).to eq(reauthenticate_form_path)
        newflow_reauthenticate_user('user@example.com', 'password')
        screenshot!
        expect(page.current_path).to eq(change_password_form_path)
        fill_in('change_password_form_password', with: 'newpassword')
        screenshot!
        find('#login-signup-form').click
        wait_for_animations
        find('[type=submit]').click
        screenshot!

        expect_newflow_profile_page
        screenshot!

        # Don't have to reauthenticate since just did
        find('.authentication[data-provider="identity"] .edit--newflow').click
        expect(page).to have_content(t(:"login_signup_form.enter_new_password_description"))
        fill_in('change_password_form_password', with: 'newpassword2')
        find('#login-signup-form').click
        wait_for_animations
        find('[type=submit]').click
        expect_newflow_profile_page
      end
    end
  end

  scenario 'bad password on reauthentication' do
    create_user 'user'
    log_in('user', 'password')

    Timecop.freeze(Time.now + RequireRecentSignin::REAUTHENTICATE_AFTER) do
      visit '/profile'
      expect_profile_page

      find('.authentication[data-provider="identity"] .edit').click

      expect(page).to have_content(t :"sessions.reauthenticate.page_heading")
      complete_login_password_screen('wrongpassword')
      screenshot!

      expect(page).to have_content(t :"sessions.reauthenticate.page_heading")
      complete_login_password_screen('password')

      complete_reset_password_screen
      complete_reset_password_success_screen
    end
  end

  scenario 'removing an authentication' do
    with_forgery_protection do
      user = create_newflow_user 'user@example.com'
      FactoryBot.create :authentication, user: user, provider: 'twitter'

      newflow_log_in_user('user@example.com', 'password')

      expect(page).to have_no_missing_translations
      Timecop.freeze(Time.now + RequireRecentSignin::REAUTHENTICATE_AFTER) do
        visit '/profile'
        expect_newflow_profile_page
        expect(page).to have_content('Twitter')
        screenshot!

        find('.authentication[data-provider="twitter"] .delete--newflow').click
        screenshot!
        click_button 'OK'
        screenshot!

        newflow_reauthenticate_user('user@example.com', 'password')
        expect_newflow_profile_page
        screenshot!

        find('.authentication[data-provider="twitter"] .delete--newflow').click
        click_button 'OK'
        expect(page).to have_no_content('Twitter')
        screenshot!
      end
    end
  end
end
