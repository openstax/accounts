require 'rails_helper'

require_relative './adding_and_resetting_password_from_profile'

feature 'Password reset', js: true do
  before do
    turn_on_student_feature_flag
    user.update!(role: User::STUDENT_ROLE)
  end

  let!(:user) {
    create_newflow_user('user@openstax.org', 'password', terms_agreed: true)
  }

  it_behaves_like 'adding and resetting password from profile', :reset

  scenario 'while still logged in – user is not stuck in a loop' do
    login_token = generate_login_token_for_user(user)
    newflow_log_in_user('user@openstax.org', 'password')
    visit profile_newflow_path
    expect(page).to have_current_path(profile_newflow_path)

    Timecop.freeze(Time.now + RequireRecentSignin::REAUTHENTICATE_AFTER) do
      find('[data-provider=identity] .edit--newflow').click
      expect(page).to have_current_path(reauthenticate_form_path)
      expect(page).to have_content(I18n.t(:"login_signup_form.login_page_header"))

      click_link(t(:"login_signup_form.forgot_password"))
      wait_for_animations
      expect(page).to have_content(
        strip_html(
          t(:'login_signup_form.password_reset_email_sent_description', email: 'user@openstax.org')
        )
      )

      perform_enqueued_jobs

      open_email('user@openstax.org')
      password_reset_link = get_path_from_absolute_link(current_email, 'a')
      visit password_reset_link

      expect(page).not_to(have_current_path(reauthenticate_form_path))
      expect(page).to(have_current_path(change_password_form_path(token: login_token)))
    end
  end

  scenario 'with identity gets redirected to reset password' do
    @user = create_user('user', 'password', terms_agreed: true)
    @login_token = generate_login_token_for 'user'
    visit password_add_path(token: @login_token)
    expect(page).to have_current_path password_reset_path
  end
end
