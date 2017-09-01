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
  user
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
  click_button (t :"sessions.start.next")
  fill_in 'login_password', with: password
  click_button (t :"sessions.authenticate_options.login")
end

def create_new_application(trusted = false)
  click_link 'New Application'
  fill_in 'Name', with: 'example'
  fill_in 'Redirect URI', with: 'https://localhost/'
  check 'Trusted?' if trusted
  click_button 'Submit'
end

def create_email_address_for(user, email_address, confirmation_code=nil)
  FactoryGirl.create(:email_address, user: user, value: email_address,
                     confirmation_code: confirmation_code,
                     verified: confirmation_code.nil?)
end

def generate_login_token_for(username)
  user = User.find_by_username(username)
  user.refresh_login_token
  user.save!
  user.login_token
end

def generate_expired_login_token_for(username)
  user = User.find_by_username(username)
  user.refresh_login_token
  user.login_token_expires_at = 1.year.ago
  user.save!
  user.login_token
end

def link_in_last_email
  mail = ActionMailer::Base.deliveries.last
  /http:\/\/[^\/]*(\/[^\s]*)/.match(mail.body.encoded)[1]
end

def create_application(skip_terms: false)
  app = FactoryGirl.create(:doorkeeper_application, :trusted, skip_terms: skip_terms)

  # We want to provide a local "external" redirect uri so our specs aren't actually
  # making HTTP calls against real external URLs like "example.com"
  server = Capybara.current_session.try(:server)
  redirect_uri = server.present? ?
                 "http://#{server.host}:#{server.port}/#{external_app_for_specs_path}" :
                 external_app_for_specs_url
  app.update_column(:redirect_uri, redirect_uri)

  FactoryGirl.create(:doorkeeper_access_token,
                     application: app, resource_owner_id: nil)
  app
end

def create_default_application
  @app = create_application
end

def capybara_url(path)
  server = Capybara.current_session.try(:server)
  raise "no capybara server" if server.nil?
  "http://#{server.host}:#{server.port}/#{path.starts_with?('/') ? path[1..-1] : path}"
end

def with_forgery_protection
  begin
    allow_any_instance_of(ActionController::Base).to receive(:allow_forgery_protection).and_return(true)
    yield if block_given?
  ensure
    allow_any_instance_of(ActionController::Base).to receive(:allow_forgery_protection).and_call_original
  end
end

def allow_forgery_protection
  allow_any_instance_of(ActionController::Base).to receive(:allow_forgery_protection).and_return(true)
  allow(ActionController::Base).to receive(:allow_forgery_protection).and_return(true)
end

def mock_bad_csrf_token
  original_rr_params = Rack::Request.instance_method(:params)
  allow_any_instance_of(Rack::Request).to receive(:params) do |request|
    original_rr_params.bind(request).call.merge('authenticity_token' => 'Invalid!')
  end
end

def visit_authorize_uri(app: @app, params: {})
  visit "/oauth/authorize?redirect_uri=#{app.redirect_uri}&" \
                         "response_type=code&" \
                         "client_id=#{app.uid}" \
                         "#{'&' + params.to_query if params.any?}"
end

def app_callback_url(app: nil)
  /^#{(app || @app).redirect_uri}\?code=.+$/
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

    [:facebook, :google_oauth2, :twitter].each do |provider|
      OmniAuth.config.mock_auth[provider] = OmniAuth::AuthHash.new({
        uid: options[:uid],
        provider: provider.to_s,
        info: { nickname: options[:nickname], email: options[:email] }
      })
    end

    yield
  ensure
    OmniAuth.config.test_mode = false
  end
end

def with_omniauth_failure_message(message)
  begin
    OmniAuth.config.test_mode = true

    [:facebook, :google_oauth2, :twitter, :identity].each do |provider|
      OmniAuth.config.mock_auth[provider] = message
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

def click_password_sign_up  # TODO remove, bad name
  click_on (t :"sessions.start.sign_up")
end

def click_sign_up
  click_on (t :"sessions.start.sign_up")
  expect(page).to have_no_missing_translations
  expect(page).to have_content(t :"signup.start.page_heading")
end

def expect_sign_in_page
  expect(page).to have_no_missing_translations
  expect(page).to have_content(t :"sessions.start.page_heading")
end

def expect_sign_up_page
  expect(page).to have_no_missing_translations
  expect(page).to have_content(t :"signup.start.page_heading")
end

def expect_authenticate_page
  expect(page.body).to match(/Hi.*!/)
end

def expect_social_sign_up_page
  expect(page).to have_no_missing_translations
  expect(page).to have_content(t :"signup.new_account.password_managed_by", manager: '')
end

def expect_profile_page
  expect(page).to have_no_missing_translations
  expect(page).to have_content(t :"users.edit.page_heading")
  expect(page).to have_current_path profile_path
end

def agree_and_click_create
  find(:css, '#signup_i_agree').set(true)
  click_button (t :"signup.new_account.create_account")
end

def arrive_from_app(app: nil, params: {}, do_expect: true)
  create_default_application unless app.present? || @app.present?
  visit_authorize_uri(app: app || @app, params: params)
  expect_sign_in_page if do_expect
end

def expect_back_at_app(app: nil)
  expect(page.current_url).to match(app_callback_url(app: app || @app))
end

def expect_signup_verify_screen
  expect(page).to have_content(t :'signup.verify_email.page_heading_pin')
end

def expect_signup_password_screen
  expect(page).to have_content(t :"signup.password.page_heading")
end

def expect_signup_profile_screen
  expect(page).to have_content(t :"signup.profile.page_heading")
end

def complete_login_username_or_email_screen(username_or_email)
  fill_in 'login_username_or_email', with: username_or_email
  expect_sign_in_page
  expect(page).to have_no_missing_translations
  click_button (t :"sessions.start.next")
  expect(page).to have_no_missing_translations

end

def complete_login_password_screen(password)
  # TODO expect login password screen
  fill_in (t :"sessions.authenticate_options.password"), with: password
  expect(page).to have_no_missing_translations
  click_button (t :"sessions.authenticate_options.login")
  expect(page).to have_no_missing_translations
end

def complete_signup_email_screen(role, email, options={})
  options[:screenshot_after_role] ||= false
  options[:only_one_next] ||= false

  @signup_email = email
  expect(page).to have_content(t :"signup.start.page_heading")
  select role, from: "signup_role"
  if options[:screenshot_after_role]
    wait_for_animations
    screenshot!
  end
  fill_in (t :"signup.start.email_placeholder"), with: email
  expect(page).to have_no_missing_translations
  click_button(t :"signup.start.next")

  expecting_institutional_email_warning = !(email =~ /\.edu$/) && !role.match(/student/i)

  click_button(t :"signup.start.next") unless !expecting_institutional_email_warning ||
                                              options[:only_one_next]

  if !(options[:only_one_next] && expecting_institutional_email_warning)
    expect(page).to have_no_missing_translations
    expect(page).to have_content(t :"signup.verify_email.page_heading_pin")
  end
end

def complete_signup_verify_screen(pin: nil, pass: nil)
  tries = 0
  while (tries+=1) < 100 && (ss = SignupState.find_by(contact_info_value: @signup_email)).nil? do
    sleep(0.1) # transaction from earlier step may not have committed
  end
  fail("unable to find email #{@signup_email}.  Did creation step fail silently?") if ss.nil?
  if pin.nil?
    raise "Must set either `pin` or `pass`" if pass.nil?
    pin = ss.confirmation_pin
    pin[0] = (9-pin[0].to_i).to_s if !pass
  end
  fill_in (t :"signup.verify_email.pin"), with: pin
  expect(page).to have_no_missing_translations
  click_button (t :"signup.verify_email.confirm")
  expect(page).to have_no_missing_translations
end

def complete_signup_password_screen(password, confirmation=nil)
  confirmation ||= password
  fill_in 'signup_password', with: password
  fill_in (t :"signup.password.password_confirmation"), with: confirmation

  expect(page).to have_content(t :"signup.password.page_heading")
  expect(page).to have_no_missing_translations
  click_button (t :"signup.password.create_password")
  expect(page).to have_no_missing_translations
end

def complete_signup_profile_screen(role:, first_name: "", last_name: "", suffix: nil,
                                   phone_number: "", school: "", url: "", num_students: "",
                                   using_openstax: "", newsletter: true, subjects: [], agree: true)

  raise IllegalArgument unless [:student, :instructor, :other].include?(role)

  fill_in (t :"signup.profile.first_name"), with: first_name
  fill_in (t :"signup.profile.last_name"), with: last_name
  fill_in (t :"signup.profile.suffix"), with: suffix if suffix.present?
  fill_in (t :"signup.profile.phone_number"), with: phone_number if role != :student
  fill_in (t :"signup.profile.school"), with: school
  fill_in (t :"signup.profile.url"), with: url if role != :student
  fill_in (t :"signup.profile.num_students"), with: num_students if role == :instructor
  select using_openstax, from: "profile_using_openstax" if !using_openstax.blank? if role == :instructor
  if role != :student
    subjects.each do |subject|
      find_field(subject).set("1")
    end
  end
  expect(page).to have_content(t :"signup.profile.page_heading")
  expect(page).to have_no_missing_translations

  find(:css, '#profile_i_agree').trigger('click') if agree

  click_button (t :"signup.profile.create_account")
  expect(page).to have_no_missing_translations
end

def complete_signup_profile_screen_with_whatever(role: :instructor)
  complete_signup_profile_screen(
    role: role,
    first_name: "Bob",
    last_name: "Armstrong",
    phone_number: "634-5789",
    school: "Rice University",
    url: "http://www.ece.rice.edu/boba",
    num_students: 30,
    subjects: ["Biology"],
    using_openstax: "primary",
    newsletter: true,
    agree: true
  )
end

def complete_reset_password_screen(password=nil)
  password ||= 'Passw0rd!'
  fill_in (t :"identities.set.password"), with: password
  fill_in (t :"identities.set.confirm_password"), with: password
  click_button (t :"identities.reset.submit")
  expect(page).to have_content(t :"identities.reset_success.message")
end

def complete_reset_password_success_screen
  click_button (t :"identities.reset_success.continue")
end

def complete_add_password_screen(password=nil)
  password ||= 'Passw0rd!'
  fill_in (t :"identities.set.password"), with: password
  fill_in (t :"identities.set.confirm_password"), with: password
  click_button (t :"identities.add.submit")
  expect(page).to have_content(t :"identities.add_success.message")
end

def complete_add_password_success_screen
  click_button (t :"identities.add_success.continue")
end

def complete_terms_screens

  find(:css, '#agreement_i_agree').set(true)
  expect(page).to have_content('Terms of Use')
  click_button (t :"terms.pose.agree")

  expect(page).to have_content('Privacy Policy')
  find(:css, '#agreement_i_agree').set(true)
  click_button (t :"terms.pose.agree")
end

def complete_instructor_access_pending_screen
  expect(page).to have_content(t :"signup.instructor_access_pending.message")
  click_button (t :"signup.instructor_access_pending.ok")
end

def log_in(username_or_email, password)
  visit '/'
  complete_login_username_or_email_screen(username_or_email)
  complete_login_password_screen(password)
end

def log_out
  visit '/logout'
end

def call_embedded_screenshots
  begin
    original_value = @call_embedded_screenshots
    @call_embedded_screenshots = true
    yield
  ensure
    @call_embedded_screenshots = original_value
  end
end

def complete_faculty_access_apply_screen(role: nil, first_name: nil, last_name: nil, suffix: nil,
                                         email: "", phone_number: "", school: "", url: "",
                                         num_students: "", using_openstax: "", newsletter: true,
                                         subjects: [])

  if role.present?
    raise IllegalArgument unless [:instructor, :other].include?(role)
    screenshot! if @call_embedded_screenshots
    select role.to_s.capitalize, from: "apply_role"
    wait_for_animations
    wait_for_ajax
  end

  expect(page).to have_content(t :"faculty_access.apply.page_heading")
  expect(page).to have_no_missing_translations

  screenshot! if @call_embedded_screenshots

  fill_in (t :"faculty_access.apply.first_name"), with: first_name if !first_name.nil?
  fill_in (t :"faculty_access.apply.last_name"), with: last_name if !last_name.nil?
  fill_in (t :"faculty_access.apply.suffix"), with: suffix if suffix.present?
  fill_in (t :"faculty_access.apply.email_placeholder"), with: email
  fill_in (t :"faculty_access.apply.phone_number"), with: phone_number
  fill_in (t :"faculty_access.apply.school"), with: school
  fill_in (t :"faculty_access.apply.url"), with: url if role != :student
  fill_in (t :"faculty_access.apply.num_students"), with: num_students if role == :instructor
  select using_openstax, from: "apply_using_openstax" if !using_openstax.blank? if role == :instructor

  subjects.each do |subject|
    find_field(subject).set("1")
  end
  page.check('apply[newsletter]') if newsletter
  click_button (t :"faculty_access.apply.submit")
  expect(page).to have_no_missing_translations
end

def mock_current_user(user)
  # The following mocks are a little faster than:
  #   visit '/'
  #   complete_login_username_or_email_screen(user.username)
  #   complete_login_password_screen('password')
  # when real recent logins don't matter

  allow_any_instance_of(ActionController::Base).to receive(:current_user) { user }
  allow_any_instance_of(UserSessionManagement).to receive(:current_user) { user }
end

def get_path_from_absolute_link(node, xpath)
  uri = URI(node.find(xpath)['href'])
  "#{uri.path}?#{uri.query}"
end

def expect_security_log(*args)
  expect_any_instance_of(ActionController::Base).to receive(:security_log)
                                                .with(*args)
                                                .and_call_original
end
