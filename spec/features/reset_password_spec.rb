require 'rails_helper'

feature 'User resets password', js: true do
  background do
    @user = create_user 'user'
    @reset_code = generate_reset_code_for 'user'
  end

  scenario 'using a link without a code' do
    visit '/reset_password'
    expect(page).to have_no_missing_translations
    expect(page).to have_content(t :"handlers.identities_reset_password.reset_link_is_invalid")
    expect(page).to have_current_path reset_password_path
  end

  scenario 'using a link with an invalid code' do
    visit '/reset_password?code=1234'
    expect(page).to have_no_missing_translations
    expect(page).to have_content(t :"handlers.identities_reset_password.reset_link_is_invalid")
    expect(page).to have_current_path reset_password_path(code: '1234')
  end

  scenario 'using a link with an expired code' do
    @reset_code = generate_expired_reset_code_for 'user'
    visit "/reset_password?code=#{@reset_code}"
    expect(page).to have_no_missing_translations
    expect(page).to have_content(t :"handlers.identities_reset_password.reset_link_expired")
    expect(page).to have_current_path reset_password_path(code: @reset_code)
  end

  scenario 'using a link with a valid code' do
    visit "/reset_password?code=#{@reset_code}"
    expect(page).to have_no_missing_translations
    expect(page).not_to have_content(t :"handlers.identities_reset_password.reset_link_is_invalid")
    expect(page).to have_current_path reset_password_path(code: @reset_code)
  end

  scenario 'with a blank password' do
    visit "/reset_password?code=#{@reset_code}"
    expect(page).to have_no_missing_translations
    expect(page).not_to have_content(t :"handlers.identities_reset_password.reset_link_is_invalid")
    expect(page).to have_current_path reset_password_path(code: @reset_code)
    click_button (t :"identities.reset_password.set_password")
    expect(page).to have_content("Password can't be blank")
    expect(page).to have_content("Password is too short")
  end

  scenario 'password is too short' do
    visit "/reset_password?code=#{@reset_code}"
    expect(page).to have_no_missing_translations
    expect(page).not_to have_content(t :"handlers.identities_reset_password.reset_link_is_invalid")
    expect(page).to have_current_path reset_password_path(code: @reset_code)
    fill_in (t :"identities.reset_password.password"), with: 'pass'
    fill_in (t :"identities.reset_password.confirm_password"), with: 'pass'
    click_button (t :"identities.reset_password.set_password")
    expect(page).to have_content('Password is too short')
  end

  scenario "password and password confirmation don't match" do
    visit "/reset_password?code=#{@reset_code}"
    expect(page).to have_no_missing_translations
    expect(page).not_to have_content(t :"handlers.identities_reset_password.reset_link_is_invalid")
    expect(page).to have_current_path reset_password_path(code: @reset_code)
    fill_in (t :"identities.reset_password.password"), with: 'password!'
    fill_in (t :"identities.reset_password.confirm_password"), with: 'password!!'
    click_button (t :"identities.reset_password.set_password")
    expect(page).to have_content("Password confirmation doesn't match Password")
  end

  scenario 'successful' do
    visit "/reset_password?code=#{@reset_code}"
    expect(page).to have_no_missing_translations
    expect(page).not_to have_content(t :"handlers.identities_reset_password.reset_link_is_invalid")
    fill_in (t :"identities.reset_password.password"), with: '1234abcd'
    fill_in (t :"identities.reset_password.confirm_password"), with: '1234abcd'
    click_button (t :"identities.reset_password.set_password")
    expect(page).to have_content(t :"controllers.identities.password_reset_successfully")

    expect_profile_page

    click_link (t :"users.edit.sign_out")
    expect(page).to have_current_path login_path

    # try logging in with the old password
    complete_login_username_or_email_screen 'user'
    complete_login_password_screen 'password'
    expect(page).to have_content(t :"controllers.sessions.incorrect_password")

    # try logging in with the new password
    complete_login_password_screen '1234abcd'

    expect_profile_page
    expect(page).to have_no_missing_translations
    expect(page).to have_content(@user.full_name)

    click_link (t :"users.edit.sign_out")

    # check that the reset password link cannot be reused again
    visit "/reset_password?code=#{@reset_code}"
    expect(page).to have_no_missing_translations
    expect(page).to have_content(t :"handlers.identities_reset_password.reset_link_expired")
  end

  scenario 'without identity' do
    visit '/signin'
    expect(page).to have_no_missing_translations
    complete_login_username_or_email_screen 'user'
    complete_login_password_screen 'password'

    expect_profile_page

    @user.identity.destroy
    visit '/reset_password'
    expect(page).to have_no_missing_translations
    expect(page).to(
      have_content(t :"controllers.identities.cannot_reset_password_because_user_doesnt_have_one")
    )
    expect_profile_page
  end

end
