module FeatureHelper
  def create_user(email, password = 'password', terms_agreed = nil, confirmation_code = nil, role = 'student')
    terms_agreed_option = (terms_agreed.nil? || terms_agreed) ? :terms_agreed : :terms_not_agreed

    user = FactoryBot.create(:user, terms_agreed_option, role: role)

    FactoryBot.create(:email_address, user: user, value: email,
                      confirmation_code:    confirmation_code,
                      verified:             confirmation_code.nil?)

    identity = FactoryBot.create :identity, user: user, password: password
    FactoryBot.create :authentication, user: user, provider: 'identity', uid: identity.uid

    user
  end

  def create_admin_user
    user = create_user 'admin@openstax.org'
    user.update!(is_administrator: true)
    user
  end

  def create_nonlocal_user(username, provider = 'facebook')
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

  def login_admin
    login(:admin)
  end

  def login(user)
    @current_user = user
  end

  def current_user
    User.find(request.session[:user])
  end

  def log_in_user(username_or_email, password = 'password')
    visit(:login_path)
    fill_in('login_form[email]', with: username_or_email).native
    fill_in('login_form[password]', with: password)
    click_button 'Continue'
  end

  def create_email_address_for(user, email_address, confirmation_code = nil)
    FactoryBot.create(:email_address, user: user, value: email_address,
                       confirmation_code: confirmation_code,
                       verified: confirmation_code.nil?)
  end

  def generate_login_token_for(user)
    user = User.find_by(uuid: user.uuid)
    user.refresh_login_token
    user.save!
    user.login_token
  end

  def create_application(skip_terms: false)
    app = FactoryBot.create(:doorkeeper_application, skip_terms: skip_terms,
                            can_access_private_user_data: true,
                            can_skip_oauth_screen: true)

    # We want to provide a local "external" redirect uri so our specs aren't actually
    # making HTTP calls against real external URLs like "example.com"

    server = Capybara.current_session.try(:server)
    host_and_port = server.present? ? "#{server.host}:#{server.port}" : nil

    redirect_uri = if host_and_port.present?
                     "http://#{host_and_port}#{external_app_for_specs_path}"
                   else
                     external_app_for_specs_url
                   end

    app.update_columns(redirect_uri: redirect_uri) # rubocop:disable Rails/SkipsModelValidations

    FactoryBot.create(:doorkeeper_access_token, application: app, resource_owner_id: nil)
    @app = app
  end

  def capybara_url(path)
    server = Capybara.current_session.try(:server)
    raise "no capybara server" if server.nil?
    "http://#{server.host}:#{server.port}/#{path.starts_with?('/') ? path[1..-1] : path}"
  end

  # to make sure that the plumbing is all working for forgery protection
  def with_forgery_protection
      allow_any_instance_of(ActionController::Base).to receive(:allow_forgery_protection).and_return(true)
      yield if block_given?
    ensure
      allow_any_instance_of(ActionController::Base).to receive(:allow_forgery_protection).and_call_original
  end

  def allow_forgery_protection
    allow_any_instance_of(ActionController::Base).to receive(:allow_forgery_protection).and_return(true)
    allow(ActionController::Base).to receive(:allow_forgery_protection).and_return(true)
  end

  def visit_authorize_uri(app: @app, params: {})
    visit "/oauth/authorize?redirect_uri=#{app.redirect_uri}&" \
          "response_type=code&" \
          "client_id=#{app.uid}" \
          "#{'&' + params.to_query if params.any?}"
  end

  def expect_back_at_app(app: nil)
    expect(page.current_url).to match(/^#{(app || @app).redirect_uri}\?code=.+$/)
  end

  # TODO: the two methods below are nearly identical
  # Call this method with a block to test login/signup with a social network
  def simulate_login_signup_with_social(options = {})
    options[:name]     ||= Faker::Name.name
    options[:nickname] ||= Faker::Internet.username
    options[:uid]      ||= Faker::Internet.uuid

    begin
      OmniAuth.config.test_mode = true

      if options[:identity_user].present?
        identity_uid = options[:identity_user].identity.id.to_s

        OmniAuth.config.mock_auth[:identity] =
          OmniAuth::AuthHash.new({
                                   uid:      identity_uid,
                                   provider: 'identity',
                                   info:     {}
                                 })
      end

      [:google, :facebook].each do |provider|
        OmniAuth.config.mock_auth[provider] =
          OmniAuth::AuthHash.new({
                                   uid:      options[:uid],
                                   provider: provider.to_s,
                                   info:     { name: options[:name], nickname: options[:nickname], email: options[:email] }
                                 })
      end

      yield
    ensure
      OmniAuth.config.test_mode = false
    end
  end

  # Call this method with a block to test social signins
  def with_omniauth_test_mode(options = {})
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

      [:facebook, :google].each do |provider|
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

  def arrive_from_app(app: nil, params: {}, do_expect: true)
    create_application unless app.present? || @app.present?
    visit_authorize_uri(app: app || @app, params: params)
    expect(page.current_url).to match(:login_path) if do_expect
  end

  def submit_signup_form
    check('signup_terms_accepted')
    wait_for_ajax
    wait_for_animations
    find('[type=submit]').click
    wait_for_ajax
    wait_for_animations
  end

  def log_in(username_or_email, password = 'password')
    log_in_user(username_or_email, password)
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

  def strip_html(text)
    ActionView::Base.full_sanitizer.sanitize(text)
  end

  def expect_security_log(*args)
    expect_any_instance_of(ActionController::Base).to receive(:security_log)
                                                  .with(*args)
                                                  .and_call_original
  end
end
