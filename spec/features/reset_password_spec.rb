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
    expect_not_reset_password_page
  end

  scenario 'using a link with an invalid code' do
    visit '/reset_password?code=1234'
    expect(page).to have_no_missing_translations
    expect(page).to have_content(t :"handlers.identities_reset_password.reset_link_is_invalid")
    expect_not_reset_password_page
  end

  scenario 'using a link with an expired code' do
    @reset_code = generate_expired_reset_code_for 'user'
    visit "/reset_password?code=#{@reset_code}"
    expect(page).to have_no_missing_translations
    expect(page).to have_content(t :"handlers.identities_reset_password.reset_link_expired")
    expect_not_reset_password_page
  end

  scenario 'using a link with a valid code' do
    visit "/reset_password?code=#{@reset_code}"
    expect(page).to have_no_missing_translations
    expect(page).not_to have_content(t :"handlers.identities_reset_password.reset_link_is_invalid")
    expect_reset_password_page
  end

  scenario 'with a blank password' do
    visit "/reset_password?code=#{@reset_code}"
    expect(page).to have_no_missing_translations
    expect(page).not_to have_content(t :"handlers.identities_reset_password.reset_link_is_invalid")
    expect_reset_password_page
    click_button (t :"identities.reset_password.set_password")
    expect(page).to have_content("Password can't be blank")
  end

  scenario 'password is too short' do
    visit "/reset_password?code=#{@reset_code}"
    expect(page).to have_no_missing_translations
    expect(page).not_to have_content(t :"handlers.identities_reset_password.reset_link_is_invalid")
    expect_reset_password_page
    fill_in (t :"identities.reset_password.password"), with: 'pass'
    fill_in (t :"identities.reset_password.confirm_password"), with: 'pass'
    click_button (t :"identities.reset_password.set_password")
    expect(page).to have_content('Password is too short')
  end

  scenario "password and password confirmation don't match" do
    visit "/reset_password?code=#{@reset_code}"
    expect(page).to have_no_missing_translations
    expect(page).not_to have_content(t :"handlers.identities_reset_password.reset_link_is_invalid")
    expect_reset_password_page
    fill_in (t :"identities.reset_password.password"), with: 'password!'
    fill_in (t :"identities.reset_password.confirm_password"), with: 'password!!'
    click_button (t :"identities.reset_password.set_password")
    expect(page).to have_content("Password confirmation doesn't match Password")
  end

  scenario 'successful' do
    visit "/reset_password?code=#{@reset_code}"
    expect(page).to have_no_missing_translations
    expect(page).not_to have_content(t :"handlers.identities_reset_password.reset_link_is_invalid")
    expect_reset_password_page
    fill_in (t :"identities.reset_password.password"), with: '1234abcd'
    fill_in (t :"identities.reset_password.confirm_password"), with: '1234abcd'
    click_button (t :"identities.reset_password.set_password")
    expect(page).to have_content(t :"controllers.identities.password_reset_successfully")

    click_link (t :"layouts.application_header.sign_out")

    # try logging in with the old password
    expect(page).to have_no_missing_translations
    fill_in (t :"sessions.new.username_or_email"), with: 'user'
    fill_in (t :"sessions.new.password"), with: 'password'
    click_button (t :"sessions.new.sign_in")
    expect(page).to have_no_missing_translations
    expect(page).to have_content(t :"controllers.sessions.incorrect_password")

    # try logging in with the new password
    fill_in (t :"sessions.new.username_or_email"), with: 'user'
    fill_in (t :"sessions.new.password"), with: '1234abcd'
    click_button (t :"sessions.new.sign_in")
    expect(page).to have_no_missing_translations
    expect(page).to have_content(t :"layouts.application_header.welcome_html", username: 'user')
    click_link (t :"layouts.application_header.sign_out")

    # check that the reset password link cannot be reused again
    visit "/reset_password?code=#{@reset_code}"
    expect(page).to have_no_missing_translations
    expect(page).to have_content(t :"handlers.identities_reset_password.reset_link_expired")
  end

  scenario 'without identity' do
    visit '/signin'
    expect(page).to have_no_missing_translations
    fill_in (t :"sessions.new.username_or_email"), with: 'user'
    fill_in (t :"sessions.new.password"), with: 'password'
    click_button (t :"sessions.new.sign_in")
    expect_profile_page
    @user.identity.destroy
    visit '/reset_password'
    expect(page).to have_no_missing_translations
    expect_profile_page
    expect(page).to(
      have_content(t :"controllers.identities.cannot_reset_password_because_user_doesnt_have_one")
    )
    expect_not_reset_password_page
  end

  def expect_reset_password_page
    expect(page).to have_no_missing_translations
    expect(page).to have_content(t :"identities.reset_password.confirm_password")
  end

  def expect_not_reset_password_page
    expect(page).to have_no_missing_translations
    expect(page).not_to have_content(t :"identities.reset_password.confirm_password")
  end

end
