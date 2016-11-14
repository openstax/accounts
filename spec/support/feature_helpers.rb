require 'import_users'

def create_user(username, password='password', terms_agreed=nil)
  terms_agreed_option = (terms_agreed.nil? || terms_agreed) ?
                          :terms_agreed :
                          :terms_not_agreed

  return if User.find_by_username(username).present?

  user = FactoryGirl.create :user, terms_agreed_option, username: username
  identity = FactoryGirl.create :identity, user: user, password: password
  authentication = FactoryGirl.create :authentication, user: user,
                                                       provider: 'identity',
                                                       uid: identity.uid
  return user
end

def imported_user username
  ImportUsers.new('some.csv', nil).create_user(
    username, '{SSHA}RmBlDXdkdJaQkDsr790+eKaY9xHQdPVNwD/B', 'Dr', 'Full', 'Name', 'user@example.com')
end

def create_user_with_plone_password
  user = create_user 'plone_user'
  # update user's password digest to be "password" using the plone hashing algorithm
  user.identity.update_attribute(:password_digest, '{SSHA}RmBlDXdkdJaQkDsr790+eKaY9xHQdPVNwD/B')
  user
end

def create_admin_user
  user = create_user 'admin'
  user.is_administrator = true
  user.save
end

def create_nonlocal_user(username, provider='facebook')
  auth_data =
    case provider
    when 'facebook' then {info: {name: username}, provider: 'facebook'}  # FB dropped nickname
    when 'google' then {info: {nickname: username}, provider: 'google'}
    when 'twitter' then {info: {nickname: username}, provider: 'twitter'}
    end
  data = OmniauthData.new(auth_data)

  user = FactoryGirl.create(:user)
  result = TransferOmniauthData.call(data, user)
  raise "create_nonlocal_user for #{username} failed" if result.errors.any?
  user.save!

  email = create_email_address_for(user, "#{username}@example.org")
  MarkContactInfoVerified.call(email)
  user
end

def signin_as username, password='password'
  fill_in 'login_username_or_email', with: username
  click_button (t :"sessions.new.next")
  fill_in 'login_password', with: password
  click_button (t :"sessions.authenticate.login")
end

def create_new_application(trusted = false)
  click_link 'New Application'
  fill_in 'Name', with: 'example'
  fill_in 'Callback urls', with: 'https://localhost/'
  check 'Trusted?' if trusted
  click_button 'Submit'
end

def create_email_address_for(user, email_address, confirmation_code=nil)
  FactoryGirl.create(:email_address, user: user, value: email_address,
                     confirmation_code: confirmation_code,
                     verified: confirmation_code.nil?)
end

def generate_reset_code_for(username)
  user = User.find_by_username(username)
  GeneratePasswordResetCode.call(user.identity).outputs[:code]
end

def generate_expired_reset_code_for(username)
  one_year_ago = 1.year.ago
  allow(DateTime).to receive(:now).and_return(one_year_ago)
  reset_code = generate_reset_code_for username
  allow(DateTime).to receive(:now).and_call_original
  reset_code
end

def sign_in_help_email_sent?(user)
  user_emails = user.contact_infos.email_addresses
  mail = ActionMailer::Base.deliveries.last
  expect(mail.to.length).to eq(1)
  expect(user_emails.collect {|e| e.value}).to include(mail.to[0])
  expect(mail.from).to eq(['noreply@openstax.org'])
  expect(mail.subject).to eq('[OpenStax] Instructions for signing in to your OpenStax account')
  expect(mail.body.encoded).to include("Hi #{user.casual_name},")
  unless user.identity.nil?
    code = user.identity.password_reset_code.code
    @reset_link = "/reset_password?code=#{code}"
    expect(mail.body.encoded).to include("http://localhost:2999#{@reset_link}")
  end
  social_auths = user.authentications.reject { |a| a.provider == 'identity' }
  social_auths.each do |social_auth|
    expect(mail.body.encoded).to include("Sign in with #{social_auth.display_name}")
    expect(mail.body.encoded).to include("http://localhost:2999/auth/#{social_auth.provider}")
  end
end

def link_in_last_email
  mail = ActionMailer::Base.deliveries.last
  /http:\/\/[^\/]*(\/[^\s]*)/.match(mail.body.encoded)[1]
end

def create_application
  @app = FactoryGirl.create(:doorkeeper_application, :trusted,
                            redirect_uri: 'https://www.example.com/callback')
  FactoryGirl.create(:doorkeeper_access_token,
                     application: @app, resource_owner_id: nil)
  @app
end

def with_forgery_protection
  begin
    allow_any_instance_of(ActionController::Base).to receive(:allow_forgery_protection).and_return(true)
    yield if block_given?
  ensure
    allow_any_instance_of(ActionController::Base).to receive(:allow_forgery_protection).and_call_original
  end
end

def visit_authorize_uri(app=@app)
  visit "/oauth/authorize?redirect_uri=#{app.redirect_uri}&response_type=code&client_id=#{app.uid}"
end

def app_callback_url
  /^#{@app.redirect_uri}\?code=.+$/
end

def with_error_pages
  begin
    Rails.application.config.consider_all_requests_local = false
    yield if block_given?
  ensure
    Rails.application.config.consider_all_requests_local = true
  end
end

# Call this method with a block to test social signins
def with_omniauth_test_mode(options={})
  options[:nickname] ||= 'jimbo'
  options[:uid] ||= '1337'

  begin
    OmniAuth.config.test_mode = true

    if options[:identity_user].present?
      identity_uid = options[:identity_user].identity.id.to_s

      OmniAuth.config.mock_auth[:identity] = OmniAuth::AuthHash.new({
        uid: identity_uid,
        provider: 'identity',
        info: {}
      })
    end

    [:facebook, :google, :twitter].each do |provider|
      OmniAuth.config.mock_auth[provider] = OmniAuth::AuthHash.new({
        uid: options[:uid],
        provider: provider.to_s,
        info: { nickname: options[:nickname] }
      })
    end

    yield
  ensure
    OmniAuth.config.test_mode = false
  end
end

def make_new_contract_version(contract = FinePrint::Contract.first)
  new_contract_version = contract.new_version
  raise "New contract version didn't save" unless new_contract_version.save
  new_contract_version.publish
  raise "New contract version didn't publish" unless new_contract_version.version == 2
end

def click_password_sign_up
  click_on (t :"sessions.new.sign_up")
end

def expect_sign_in_page
  expect(page).to have_no_missing_translations
  expect(page).to have_content(t :"sessions.new.page_heading")
end

def expect_social_sign_up_page
  expect(page).to have_no_missing_translations
  expect(page).to have_content(t :"signup.new_account.password_managed_by", manager: '')
end

def expect_profile_page
  expect(page).to have_no_missing_translations
  expect(page).to have_content(t :"users.edit.page_heading")
end

def agree_and_click_create
  find(:css, '#signup_i_agree').set(true)
  click_button (t :"signup.new_account.create_account")
end

def arrive_from_app
  create_application
  visit_authorize_uri
  expect_sign_in_page
end

def expect_back_at_app
  expect(page.current_url).to match(app_callback_url)
end

def expect_profile_screen
  expect(page).to have_content(t :"users.edit.page_heading")
end

def complete_username_or_email_screen(username_or_email)
  expect_sign_in_page
  expect(page).to have_no_missing_translations
  fill_in (t :"sessions.new.email_placeholder"), with: username_or_email
  click_button (t :"sessions.new.next")
  expect(page).to have_no_missing_translations
end

def complete_password_screen(password)
  fill_in (t :"sessions.authenticate.password"), with: password
  expect(page).to have_no_missing_translations
  click_button (t :"sessions.authenticate.login")
  expect(page).to have_no_missing_translations
end

def complete_reset_password_screen(password=nil)
  password ||= 'Passw0rd!'
  fill_in (t :"identities.reset_password.password"), with: password
  fill_in (t :"identities.reset_password.confirm_password"), with: password
  click_button (t :"identities.reset_password.set_password")
end

def complete_terms_screens
  expect(page).to have_content('Terms of Use')

  find(:css, '#agreement_i_agree').set(true)
  click_button (t :"terms.pose.agree")

  expect(page).to have_content('Privacy Policy')
  find(:css, '#agreement_i_agree').set(true)
  click_button (t :"terms.pose.agree")
end

