require 'rails_helper'

require_relative './add_reset_password_shared_examples'

feature 'Password reset', js: true do
  before do
    turn_on_feature_flag
  end

  it_behaves_like "add_reset_password_shared_examples", :reset

  xscenario 'while still logged in – user is not stuck in a loop' do
    # shouldn't ask to reauthenticate when they forgot their password and are trying to reset it
    # issue: https://github.com/openstax/business-intel/issues/550
    user = create_user 'user'
    create_email_address_for user, 'user@example.com'
    login_token = generate_login_token_for 'user'
    log_in('user','password')

    Timecop.freeze(Time.now + RequireRecentSignin::REAUTHENTICATE_AFTER) do
      find('[data-provider=identity] .edit').click
      expect(page).to have_content(t :"sessions.reauthenticate.page_heading")
      click_link(t :"sessions.authenticate_options.reset_password")
      expect(page).to have_content(t(:'identities.send_reset.we_sent_email', emails: 'user@example.com'))

      open_email('user@example.com')
      password_reset_link = get_path_from_absolute_link(current_email, 'a')
      visit password_reset_link

      expect(page).not_to(have_current_path(reauthenticate_path))
      expect(page).to(have_current_path(password_reset_path(token: login_token)))
    end
  end

  xscenario 'with identity gets redirected to reset password' do
    @user = create_user 'user'
    @login_token = generate_login_token_for 'user'
    visit password_add_path(token: @login_token)
    expect(page).to have_current_path password_reset_path
  end

  xscenario 'reset from reauthenticate page sends email' do
    user = create_user 'user'
    create_email_address_for user, 'user@example.com'
    log_in('user','password')

    Timecop.freeze(Time.now + RequireRecentSignin::REAUTHENTICATE_AFTER) do
      find('[data-provider=identity] .edit').click
      expect(page).to have_content(t :"sessions.reauthenticate.page_heading")
      click_link(t :"sessions.authenticate_options.reset_password")
      expect(page).to have_content(t(:'identities.send_reset.we_sent_email', emails: 'user@example.com'))
      open_email('user@example.com')
      expect(current_email).to have_content('reset')
    end
  end

  scenario 'reset password links stay constant for a fixed time' do
    user = create_user 'user'
    create_email_address_for user, 'user@example.com'

    visit '/'
    complete_login_username_or_email_screen('user@example.com')
    click_link(t :"sessions.authenticate_options.reset_password")
    open_email('user@example.com')
    reset_link_path_1 = get_path_from_absolute_link(current_email, 'a')
    clear_emails

    visit '/'
    complete_login_username_or_email_screen('user@example.com')
    click_link(t :"sessions.authenticate_options.reset_password")
    open_email('user@example.com')
    reset_link_path_2 = get_path_from_absolute_link(current_email, 'a')
    clear_emails

    expect(reset_link_path_2).to eq reset_link_path_1

    Timecop.freeze(Time.now + IdentitiesSendPasswordEmail::LOGIN_TOKEN_EXPIRES_AFTER) do
      visit '/'
      complete_login_username_or_email_screen('user@example.com')
      click_link(t :"sessions.authenticate_options.reset_password")
      open_email('user@example.com')
      reset_link_path_3 = get_path_from_absolute_link(current_email, 'a')

      expect(reset_link_path_3).not_to eq reset_link_path_1
    end
  end

  scenario 'failure to send reset email sends user back to authenticate page' do
    user = create_user 'user'
    visit '/'
    complete_login_username_or_email_screen('user')

    # Cause an error to occur in the handler that sends the email
    allow_any_instance_of(User).to receive(:save).and_wrap_original do |original_method, *args, &block|
      original_method.call(*args, &block)
      original_method.receiver.errors.add(:base, "Fake spec error")
    end

    expect_security_log(:help_request_failed, user: user)

    click_link(t :"sessions.authenticate_options.reset_password")

    expect_authenticate_page
  end

end
