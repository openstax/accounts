require 'rails_helper'

feature 'User resets password', js: true do

  [:reset, :add].each do |type|

    context type.to_s do

      before(:each) do
        @user = create_user 'user'
        @login_token = generate_login_token_for 'user'

        if :add == type
          identity_authentication = @user.authentications.first
          FactoryGirl.create :authentication, user: @user, provider: 'facebook'
          @user.identity.destroy!
          identity_authentication.destroy!
        end
      end

      scenario 'using a link without a code' do
        visit start_path(type: type)
        screenshot!
        expect(page).to have_no_missing_translations
        expect(page).to have_content(t :"identities.set.there_was_a_problem_with_password_link")
        expect(page).to have_current_path start_path(type: type)
      end

      scenario 'using a link with an invalid code' do
        visit start_path(type: type, token: '1234')
        screenshot!
        expect(page).to have_no_missing_translations
        expect(page).to have_content(t :"identities.set.there_was_a_problem_with_password_link")
        expect_page(type: type, token: '1234')
      end

      scenario 'using a link with an expired code' do
        @login_token = generate_expired_login_token_for 'user'
        visit start_path(type: type, token: @login_token)
        screenshot!
        expect(page).to have_no_missing_translations
        expect(page).to have_content(t :"identities.set.expired_password_link")
        expect_page(type: type)
      end

      scenario 'using a link with a valid code' do
        visit start_path(type: type, token: @login_token)
        expect(page).to have_no_missing_translations
        expect(page.first('#set_password_password_confirmation')["placeholder"]).to eq t :"identities.set.confirm_password"
        expect_page(type: type)
      end

      scenario 'with a blank password' do
        visit start_path(type: type, token: @login_token)
        expect_page(type: type)
        click_button (t :"identities.#{type}.submit")
        expect(page).to have_content(error_msg Identity, :password, :blank)
        screenshot!
      end

      scenario 'password is too short' do
        visit start_path(type: type, token: @login_token)
        expect(page).to have_no_missing_translations
        expect_page(type: type)
        fill_in (t :"identities.set.password"), with: 'pass'
        fill_in (t :"identities.set.confirm_password"), with: 'pass'
        click_button (t :"identities.#{type}.submit")
        expect(page).to have_content(error_msg Identity, :password, :too_short, count: 8)
        screenshot!
      end

      scenario "password and password confirmation don't match" do
        visit start_path(type: type, token: @login_token)
        expect(page).to have_no_missing_translations
        expect_page(type: type)
        fill_in (t :"identities.set.password"), with: 'password!'
        fill_in (t :"identities.set.confirm_password"), with: 'password!!'
        click_button (t :"identities.#{type}.submit")
        expect(page).to have_content(error_msg Identity, :password_confirmation, :confirmation)
        screenshot!
      end

      scenario 'successful' do
        visit start_path(type: type, token: @login_token)
        expect(page).to have_no_missing_translations
        fill_in (t :"identities.set.password"), with: '1234abcd'
        fill_in (t :"identities.set.confirm_password"), with: '1234abcd'
        click_button (t :"identities.#{type}.submit")
        expect(page).to have_content(t :"identities.#{type}_success.message")
        click_button (t :"identities.#{type}_success.continue")

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

      scenario 'cancels reset' do
        visit start_path(type: type, token: @login_token)
        expect(page).to have_no_missing_translations
        fill_in (t :"identities.set.password"), with: '1234abcd'
        fill_in (t :"identities.set.confirm_password"), with: '1234abcd'
        fill_in (t :"identities.set.confirm_password"), with: '1234abcd'
        click_link (t :"identities.set.cancel")
        expect_profile_page
        expect(@user.identity.authenticate '1234abcd').to eq(false)
      end

    end

  end

  scenario 'without identity gets redirected to add password' do
    @user = create_user 'user'
    @login_token = generate_login_token_for 'user'
    @user.identity.destroy
    visit password_reset_path(token: @login_token)
    expect(page).to have_current_path password_add_path
  end

  scenario 'with identity gets redirected to reset password' do
    @user = create_user 'user'
    @login_token = generate_login_token_for 'user'
    visit password_add_path(token: @login_token)
    expect(page).to have_current_path password_reset_path
  end

  scenario 'reset from reauthenticate page sends email' do
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

  def expect_reset_password_page(code = @login_token)
    expect(page).to have_current_path password_reset_path(token: code)
    expect(page).to have_no_missing_translations
  end

  def expect_page(type:, token: @login_token)
    expect(page).to have_current_path start_path(type: type, token: token)
    expect(page).to have_no_missing_translations
  end

  def start_path(type:, token: nil)
    case type
    when :reset
      token.present? ? password_reset_path(token: token) : password_reset_path
    when :add
      token.present? ? password_add_path(token: token) : password_add_path
    end
  end

end
