require 'rails_helper'

feature 'Require recent log in to change authentications', js: true do
  let!(:user) do
    user = create_user(email_value)
    user.update(role: 'student')
    user
  end
  let(:email_value) { 'user@example.com' }

  scenario 'adding Facebook' do
    visit '/'
    log_in_user(email_value, 'password')

    expect(page.current_path).to eq(profile_path)

    Timecop.freeze(Time.now + RequireRecentSignin::REAUTHENTICATE_AFTER) do
      expect(page).to have_no_content('Facebook')
      screenshot!
      click_link(t :"users.edit.enable_other_sign_in_options")
      wait_for_animations
      expect(page).to have_no_content(t :"users.edit.enable_other_sign_in_options")
      expect(page).to have_content((t :"users.edit.other_sign_in_options_html")[0..7])
      expect(page).to have_content('Facebook')

      with_omniauth_test_mode(identity_user: user) do
        find('.authentication[data-provider="facebook"] .add').click
        wait_for_ajax
        expect(page).to have_content(t :"login_signup_form.login_page_header")
        fill_in(t(:"login_signup_form.password_label"), with: 'password')
        find('[type=submit]').click
        expect(page.current_path).to eq(profile_path)
        expect(page).to have_content('Facebook')
      end
    end
  end

  scenario 'changing the password' do
    with_forgery_protection do
      visit '/'
      log_in_user(email_value, 'password')
      expect(page).to have_no_missing_translations

      Timecop.freeze(Time.now + RequireRecentSignin::REAUTHENTICATE_AFTER) do
        visit profile_path
        expect(page.current_path).to eq(profile_path)

        find('.authentication[data-provider="identity"] .edit').click

        expect(page.current_path).to eq(reauthenticate_form_path)

        expect(page.current_path).to eq(reauthenticate_form_path)
        expect(find('#login_form_email').value).to eq(email) # email should be pre-populated
        fill_in('login_form_password', with: 'password')
        find('[type=submit]').click

        expect(page.current_path).to eq(password_reset_path)
        fill_in('change_password_form_password', with: 'newpassword')
        find('#login-signup-form').click
        wait_for_animations
        find('[type=submit]').click

        expect_profile_page

        # Don't have to reauthenticate since just did
        find('.authentication[data-provider="identity"] .edit').click
        complete_reset_password_screen 'newpassword2'
        click_button 'Continue'
      end
    end
  end

  scenario 'bad password on reauthentication' do
    log_in_user(email_value, 'password')

    Timecop.freeze(Time.now + RequireRecentSignin::REAUTHENTICATE_AFTER) do
      visit profile_path
      expect_profile_page

      find('.authentication[data-provider="identity"] .edit').click

      fill_in(t(:"login_signup_form.password_label"), with: 'wrongpassword')
      wait_for_ajax
      wait_for_animations
      find('[type=submit]').click
      screenshot!

      fill_in(t(:"login_signup_form.password_label"), with: 'password')
      find('[type=submit]').click

      complete_reset_password_screen
      expect(page).to have_content(t :"identities.reset_success.message")
    end
  end

  scenario 'removing an authentication' do
    with_forgery_protection do
      FactoryBot.create :authentication, user: user, provider: 'facebook'

      log_in_user(email_value, 'password')

      Timecop.freeze(Time.now + RequireRecentSignin::REAUTHENTICATE_AFTER) do
        visit profile_path
        expect_profile_page
        expect(page).to have_content('Facebook')
        screenshot!

        find('.authentication[data-provider="facebook"] .delete').click
        screenshot!

        click_button 'OK'

        expect(page.current_path).to eq(reauthenticate_form_path)
        expect(find('#login_form_email').value).to eq(email) # email should be pre-populated
        fill_in('login_form_password', with: password)
        find('[type=submit]').click
        expect_profile_page

        find('.authentication[data-provider="facebook"] .delete').click
        click_button 'OK'
        expect(page).to have_no_content('Facebook')
        screenshot!
      end
    end
  end
end
