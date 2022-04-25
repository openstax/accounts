require 'rails_helper'

require_relative './adding_and_resetting_password_from_profile'

feature 'Password reset', js: true do
  before do
    user.update!(role: :student)
  end

  let!(:user) {
    create_user('user@openstax.org')
  }

  it_behaves_like 'adding and resetting password from profile', :reset

  scenario 'while still logged in – user is not stuck in a loop' do
    # shouldn't ask to reauthenticate when they forgot their password and are trying to reset it
    # issue: https://github.com/openstax/business-intel/issues/550
    user.refresh_login_token
    user.save!
    login_token = user.login_token
    log_in_user('user@openstax.org')
    expect(page).to have_current_path(profile_path)

    Timecop.freeze(Time.zone.now + RequireRecentSignin::REAUTHENTICATE_AFTER) do
      find('[data-provider=identity] .edit--newflow').click
      expect(page).to have_content(I18n.t(:'login_signup_form.login_page_header'))

      click_link(t(:'login_signup_form.forgot_password'))
      wait_for_animations
      expect(page).to have_content(
        strip_html(
          t(:'login_signup_form.password_reset_email_sent_description', email: 'user@openstax.org')
        )
      )

      open_email('user@openstax.org')
      password_reset_link = get_path_from_absolute_link(current_email, 'a')
      visit password_reset_link

      expect(page).not_to(have_current_path(reauthenticate_form_path))
      expect(page).to(have_current_path(change_password_form_path(token: login_token)))
    end
  end

  scenario 'with identity gets redirected to reset password' do
    user = create_user 'user2@openstax.org'
    @login_token = generate_login_token_for user
    visit password_add_path(token: @login_token)
    expect(page).to have_current_path password_reset_path
  end

  scenario "'Forgot password?' link from reauthenticate page sends email (bypassing Reset Password Form)" do
    log_in_user('user@openstax.org')

    Timecop.freeze(Time.zone.now + RequireRecentSignin::REAUTHENTICATE_AFTER) do
      find('[data-provider=identity] .edit--newflow').click
      expect(page).to have_content(I18n.t(:'login_signup_form.login_page_header'))
      click_link(t(:'login_signup_form.forgot_password'))
      expect(page).to have_content(
        strip_html(
          t(:'login_signup_form.password_reset_email_sent_description', email: 'user@openstax.org')
        )
      )
      open_email('user@openstax.org')
      expect(current_email).to have_content('reset')
    end
  end
end
