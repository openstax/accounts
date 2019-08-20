RSpec.shared_examples "add_reset_password_shared_examples" do |parameter|
  let(:type) { parameter }

  before(:each) do
    @user = create_user 'user'
    @login_token = generate_login_token_for 'user'

    if :add == type
      identity_authentication = @user.authentications.first
      FactoryBot.create :authentication, user: @user, provider: 'facebook'
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
    visit '/'
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
