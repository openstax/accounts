# Creates a verified user, an email address, and a password
def create_user(email_or_username, password='password', terms_agreed=nil, confirmation_code=nil, role='student')
  terms_agreed_option = (terms_agreed.nil? || terms_agreed) ?
                          :terms_agreed :
                          :terms_not_agreed

  user = if email_or_username.include? '@'
    FactoryBot.create(:user, terms_agreed_option, role: role).tap do |user|
      FactoryBot.create(:email_address, user: user, value: email_or_username,
                        confirmation_code: confirmation_code,
                        verified: confirmation_code.nil?)
    end
  else
    FactoryBot.create(:user, terms_agreed_option, username: email_or_username, role: role)
  end

  identity = FactoryBot.create :identity, user: user, password: password
  authentication = FactoryBot.create :authentication, user: user,
                                                      provider: 'identity',
                                                      uid: identity.uid
  return user
end

def create_admin_user
  user = create_user 'admin'
  user.update_attributes!(is_administrator: true)
  user
end

def create_nonlocal_user(username, provider='facebook')
  auth_data =
    case provider
    when 'facebook' then {info: {name: username}, provider: 'facebook'}  # FB dropped nickname
    when 'google' then {info: {nickname: username}, provider: 'google'}
    end
  data = OmniauthData.new(auth_data)

  user = FactoryBot.create(:user)
  result = TransferOmniauthData.call(data, user)
  raise "create_nonlocal_user for #{username} failed" if result.errors.any?
  user.save!

  email = create_email_address_for(user, "#{username}@example.org")
  MarkContactInfoVerified.call(email)
  user
end

def create_email_address_for(user, email_address, confirmation_code=nil)
  FactoryBot.create(:email_address, user: user, value: email_address,
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
  app = FactoryBot.create(:doorkeeper_application, skip_terms: skip_terms,
                          can_access_private_user_data: true,
                          can_skip_oauth_screen: true)

  # We want to provide a local "external" redirect uri so our specs aren't actually
  # making HTTP calls against real external URLs like "example.com"

  host_and_port =
    if in_docker?
      # We set these explicitly
      [Capybara.server_host, Capybara.server_port].compact.join(":")
    else
      server = Capybara.current_session.try(:server)
      server.present? ? "#{server.host}:#{server.port}" : nil
    end

  redirect_uri = host_and_port.present? ?
                 "http://#{host_and_port}#{external_app_for_specs_path}" :
                 external_app_for_specs_url

  app.update_column(:redirect_uri, redirect_uri)

  FactoryBot.create(:doorkeeper_access_token, application: app, resource_owner_id: nil)
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

# to make sure that the plumbing is all working for forgery protection
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

    [:facebook, :google_oauth2].each do |provider|
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

    [:facebook, :google_oauth2, :identity].each do |provider|
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

def expect_sign_in_page
  expect(page).to have_no_missing_translations
  expect(page).to have_content(t :"sessions.start.page_heading")
end

def expect_authenticate_page
  expect(page.body).to match(/Hello.*!/)
end

def expect_profile_page
  expect(page).to have_no_missing_translations
  expect(page).to have_current_path profile_path
end

def arrive_from_app(app: nil, params: {}, do_expect: true)
  create_default_application unless app.present? || @app.present?
  visit_authorize_uri(app: app || @app, params: params)
  expect_sign_in_page if do_expect
end

def expect_back_at_app(app: nil)
  expect(page.current_url).to match(app_callback_url(app: app || @app))
end

def complete_login_username_or_email_screen(username_or_email)
  fill_in('login_form_email', with: username_or_email).native
  expect_sign_in_page
  expect(page).to have_no_missing_translations
  screenshot!
  click_button(I18n.t(:"login_signup_form.continue_button"))
  expect(page).to have_no_missing_translations
end

def complete_login_password_screen(password)
  expect(page).to have_content(t :"sessions.authenticate_options.forgot_password")
  fill_in (t :"sessions.authenticate_options.password"), with: password
  expect(page).to have_no_missing_translations
  screenshot!
  click_button(t :"sessions.authenticate_options.login")
  expect(page).to have_no_missing_translations
end

def complete_reset_password_screen(password=nil)
  expect(page.current_path).to eq(password_reset_path)
  password ||= 'Passw0rd!'
  fill_in 'set_password_password', with: password
  fill_in 'set_password_password_confirmation', with: password
  click_button(t :"identities.reset.submit")
  expect(page.current_path).to eq(password_reset_success_path)
  expect(page).to have_content(t :"identities.reset_success.message")
end

def complete_reset_password_success_screen
  click_button(t :"identities.reset_success.continue")
end

def complete_add_password_screen(password=nil)
  expect(page.current_path).to eq(password_add_path)
  password ||= 'Passw0rd!'
  fill_in 'set_password_password', with: password
  fill_in 'set_password_password_confirmation', with: password
  click_button(t :"identities.add.submit")
  expect(page.current_path).to eq(password_add_success_path)
  expect(page).to have_content(t :"identities.add_success.message")
end

def complete_add_password_success_screen
  click_button(t :"identities.add_success.continue")
end

def complete_terms_screens(without_privacy_policy: false)

  check 'agreement_i_agree'
  expect(page).to have_content('Terms of Use')
  click_button(t :"terms.pose.agree")
  unless without_privacy_policy
    expect(page).to have_content('Privacy Policy')
    check 'agreement_i_agree'
    click_button(t :"terms.pose.agree")
  end
end

def log_in_user(username_or_email, password)
  visit(login_path) unless page.current_url == login_url
  fill_in('login_form_email', with: username_or_email).native
  expect(page).to have_no_missing_translations

  fill_in('login_form_password', with: password)
  expect(page).to have_no_missing_translations
  wait_for_animations
  wait_for_ajax
  screenshot!
  click_button(I18n.t(:"login_signup_form.continue_button"))
  wait_for_animations
  wait_for_ajax
  screenshot!
  expect(page).to have_no_missing_translations
end

def log_in(username_or_email, password = 'password')
  log_in_user(username_or_email, password)
end

def reauthenticate_user(email, password)
  wait_for_animations
  wait_for_ajax
  expect(page.current_path).to eq(reauthenticate_form_path)
  expect(find('#login_form_email').value).to eq(email) # email should be pre-populated
  fill_in('login_form_password', with: password)
  screenshot!
  find('[type=submit]').click
  wait_for_animations
end

def log_out
  visit '/logout'
end

def click_sign_up(role:)
  click_on (t :"login_signup_form.sign_up") unless page.current_path == signup_path
  expect(page).to have_no_missing_translations
  expect(page).to have_content(t :"login_signup_form.welcome_page_header")
  find(".join-as__role.#{role}").click
end

def expect_sign_up_welcome_tab
  expect(page).to have_no_missing_translations
  expect(page).to have_content(t :"login_signup_form.welcome_page_header")
end

def submit_signup_form
  check('signup_terms_accepted')
  wait_for_ajax
  wait_for_animations
  screenshot!
  find('[type=submit]').click
  wait_for_ajax
  wait_for_animations
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

  subjects.each { |subject| check subject }
  page.check('apply[newsletter]') if newsletter
  click_button (t :"faculty_access.apply.submit")
  expect(page).to have_no_missing_translations
end

def generate_login_token_for_user(user)
  user.refresh_login_token
  user.save!
  user.login_token
end

def generate_expired_login_token_for_user(user)
  user.refresh_login_token
  user.login_token_expires_at = 1.year.ago
  user.save!
  user.login_token
end

# Call this method with a block to test login/signup with a social network
def simulate_login_signup_with_social(options={})
  options[:name] ||= 'Elon Musk'
  options[:nickname] ||= 'elonmusk'
  options[:uid] ||= '1234UID'

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

    [:google_oauth2, :facebook].each do |provider|
      OmniAuth.config.mock_auth[provider] = OmniAuth::AuthHash.new({
        uid: options[:uid],
        provider: provider.to_s,
        info: { name: options[:name], nickname: options[:nickname], email: options[:email] }
      })
    end

    yield
  ensure
    OmniAuth.config.test_mode = false
  end
end

def external_public_url
  capybara_url(external_app_for_specs_path) + '/public'
end

def expect_sheerid_iframe
  within_frame do
    expect(page).to have_text('Verify your instructor status')
    expect(page.find('#sid-country')[:value]).to have_text('United States', exact: false)
    expect(page.find('#sid-teacher-school')[:value]).to be_blank
    expect(page.find('#sid-first-name')[:value]).to have_text(first_name)
    expect(page.find('#sid-last-name')[:value]).to have_text(last_name)
    expect(page.find('#sid-email')[:value]).to have_text(email_value)
    expect(page).to have_text('Can\'t find your country in the list? Click here.')
    expect(page).to have_text('Can\'t find your school in the list? Click here.')
    expect(page).to have_text('Verify my instructor status')
    screenshot!
  end
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

def strip_html(text)
  ActionView::Base.full_sanitizer.sanitize(text)
end

module Capybara
  class Session
    alias_method :original_visit, :visit
    def visit(visit_uri)
      # Note that the feature specs aren't yet modified to pass in a cloudfront simulation
      # world.  Particularly, expectations on paths are hardcoded without the /accounts
      # prefix and would need to be modified or taught how to expect during a cloudfront
      # simulation

      if ENV['SIMULATE_CLOUDFRONT'] == 'true'
        uri = URI(visit_uri)
        uri.path = "/#{OpenStax::PathPrefixer.configuration.prefix}#{uri.path}"
        visit_uri = uri.to_s
      end

      original_visit(visit_uri)
    end
  end
end
