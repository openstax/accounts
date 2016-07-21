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

  result = CreateUserFromOmniauthData.call(data)
  raise "create_nonlocal_user for #{username} failed" if result.errors.any?
  user = User.find_by_username(username)
  email = create_email_address_for(user, "#{username}@example.org")
  MarkContactInfoVerified.call(email)
  user
end

def signin_as username, password='password'
  fill_in (t :"sessions.new.username_or_email"), with: username
  fill_in (t :"sessions.new.password"), with: password
  click_button (t :"sessions.new.sign_in")
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
    expect(mail.body.encoded).to include("http://nohost#{@reset_link}")
  end
  social_auths = user.authentications.reject { |a| a.provider == 'identity' }
  social_auths.each do |social_auth|
    expect(mail.body.encoded).to include("Sign in with #{social_auth.display_name}")
    expect(mail.body.encoded).to include("http://nohost/auth/#{social_auth.provider}")
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

def click_omniauth_link(provider, options={})
  options[:nickname] ||= 'jimbo'
  options[:uid] ||= '1337'
  options[:link_id] ||= "#{provider}-login-button"

  begin
    OmniAuth.config.test_mode = true

    OmniAuth.config.mock_auth[provider.to_sym] = OmniAuth::AuthHash.new({
      uid: options[:uid],
      provider: provider,
      info: {
        nickname: options[:nickname]
      }
    })

    click_link options[:link_id]
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
  click_on (t :"signup.index.sign_up_with_password")
end

def expect_sign_in_page
  expect(page).to have_no_missing_translations
  expect(page).to have_content(t :"sessions.new.page_heading")
  expect(page).to have_content(t :"sessions.new.page_sub_heading")
end

def expect_social_sign_up_page
  expect(page).to have_no_missing_translations
  expect(page).to have_content(t :"signup.new_account.password_managed_by", manager: '')
end

def agree_and_click_create
  find(:css, '#signup_i_agree').set(true)
  click_button (t :"signup.new_account.create_account")
end
