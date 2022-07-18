require 'rails_helper'

feature 'User adds password', js: true do
  scenario 'without identity – form to create password is rendered' do
    @user = create_user 'user'
    @login_token = generate_login_token_for 'user'
    visit password_reset_path(token: @login_token)
    expect(page).to have_content(t(:"login_signup_form.setup_your_new_password"))
  end

  before(:each) do
    @user = create_user 'user'
    @login_token = generate_login_token_for 'user'

    identity_authentication = @user.authentications.first
    FactoryBot.create :authentication, user: @user, provider: 'facebook'
    @user.identity.destroy!
    identity_authentication.destroy!
  end

  scenario 'using a link without a code' do
    visit password_add_path
    expect(page).to have_content(t :"identities.set.there_was_a_problem_with_password_link")
    expect(page).to have_current_path password_add_path
  end

  scenario 'using a link with an invalid code' do
    visit password_add_path
    expect(page).to have_content(t :"identities.set.there_was_a_problem_with_password_link")
    expect(page).to have_current_path password_add_path
  end

  scenario 'using a link with an expired code' do
    @login_token = generate_expired_login_token_for_user(User.last)
    visit password_add_path
    expect(page).to have_content(t :"identities.set.expired_password_link")
    expect(page).to have_current_path password_add_path
  end

  scenario 'using a link with a valid code' do
    visit visit password_add_path
    expect(page).to have_current_path password_add_path
  end

  scenario 'with a blank password' do
    visit visit password_add_path
    expect(page).to have_current_path password_add_path
    find('#login-signup-form').click # to hide the password tooltip
    find('[type=submit]').click
    expect(page).to have_content(error_msg Identity, :password, :blank)
  end

  scenario 'password is too short' do
    visit password_reset_path
    expect(page).to have_current_path password_add_path
    fill_in (t :"login_signup_form.password_label"), with: 'pass'
    find('#login-signup-form').click # to hide the password tooltip
    find('[type=submit]').click
    expect(page).to have_content(error_msg Identity, :password, :too_short, count: 8)
  end

  scenario 'password is the same as before' do
    if type == :reset
      ident = @user.identity
      ident.password = 'password'
      ident.save!

      visit password_reset_path
      fill_in (t :"login_signup_form.password_label"), with: 'password'
      find('[type=submit]').click
      expect(page).to have_content(I18n.t(:"login_signup_form.same_password_error"))
    end
  end

  scenario 'successful' do
    visit password_reset_path
    fill_in(t(:"login_signup_form.password_label"), with: 'newpassword')
    find('#login-signup-form').click # to hide the password tooltip
    wait_for_animations
    find('[type=submit]').click
    expect(page).to have_content(t(:"identities.add_success.message"))

    expect_profile_page

    click_link (t :"users.edit.sign_out")
    visit '/'
    expect(page).to have_current_path login_path

    # try logging in with the old password
    log_in_user('user', 'password')
    expect(page).to have_content(t(:"login_signup_form.incorrect_password"))

    # try logging in with the new password
    log_in_user('user', 'newpassword')

    expect_profile_page
    expect(page).to have_content(@user.full_name)
  end
end
