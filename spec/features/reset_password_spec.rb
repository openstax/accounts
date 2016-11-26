require 'rails_helper'

feature 'User resets password', js: true do
  background do
    @user = create_user 'user'
    @login_token = generate_login_token_for 'user'
  end

  scenario 'using a link without a code' do
    visit '/reset_password'
    expect(page).to have_no_missing_translations
    expect(page).to have_content(t :"identities.there_was_a_problem_with_reset_link")
    expect(page).to have_current_path reset_password_path
  end

  scenario 'using a link with an invalid code' do
    visit '/reset_password?token=1234'
    expect(page).to have_no_missing_translations
    expect(page).to have_content(t :"identities.there_was_a_problem_with_reset_link")
    expect_reset_password_page('1234')
  end

  scenario 'using a link with an expired code' do
    @login_token = generate_expired_login_token_for 'user'
    visit "/reset_password?token=#{@login_token}"
    expect(page).to have_no_missing_translations
    expect(page).to have_content(t :"identities.expired_reset_link")
    expect_reset_password_page
  end

  scenario 'using a link with a valid code' do
    visit "/reset_password?token=#{@login_token}"
    expect(page).to have_no_missing_translations
    expect(page).to have_content(t :"identities.confirm_password")
    expect_reset_password_page
  end

  scenario 'with a blank password' do
    visit "/reset_password?token=#{@login_token}"
    expect_reset_password_page
    click_button (t :"identities.set_password")
    expect(page).to have_content("Password can't be blank")
  end

  scenario 'password is too short' do
    visit "/reset_password?token=#{@login_token}"
    expect(page).to have_no_missing_translations
    expect(page).not_to have_content(t :"handlers.identities_reset_password.reset_link_is_invalid")
    expect_reset_password_page
    fill_in (t :"identities.password"), with: 'pass'
    fill_in (t :"identities.confirm_password"), with: 'pass'
    click_button (t :"identities.set_password")
    expect(page).to have_content('Password is too short')
  end

  scenario "password and password confirmation don't match" do
    visit "/reset_password?token=#{@login_token}"
    expect(page).to have_no_missing_translations
    expect(page).not_to have_content(t :"handlers.identities_reset_password.reset_link_is_invalid")
    expect_reset_password_page
    fill_in (t :"identities.password"), with: 'password!'
    fill_in (t :"identities.confirm_password"), with: 'password!!'
    click_button (t :"identities.set_password")
    expect(page).to have_content("Password confirmation doesn't match Password")
  end

  scenario 'successful' do
    visit "/reset_password?token=#{@login_token}"
    expect(page).to have_no_missing_translations
    fill_in (t :"identities.password"), with: '1234abcd'
    fill_in (t :"identities.confirm_password"), with: '1234abcd'
    click_button (t :"identities.set_password")
    expect(page).to have_content(t :"identities.reset_password_success.message")
    click_link (t :"identities.reset_password_success.continue")

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
  end

  scenario 'without identity gets redirected to add password' do
    @user.identity.destroy
    visit "/reset_password?token=#{@login_token}"
    expect(page).to have_current_path add_password_path
  end

  def expect_reset_password_page(code = @login_token)
    expect(page).to have_current_path reset_password_path(token: code)
    expect(page).to have_no_missing_translations
  end

end
