# Creates a verified user, an email address, and a password
def create_newflow_user(email, password='password', terms_agreed=nil, confirmation_code=nil, role='student')
  terms_agreed_option = terms_agreed.nil? || terms_agreed ? :terms_agreed : :terms_not_agreed

  user ||= FactoryBot.create(:user, terms_agreed_option, role: role)

  FactoryBot.create(:email_address, user: user, value: email,
                    confirmation_code: confirmation_code,
                    verified: confirmation_code.nil?)

  identity = FactoryBot.create :identity, user: user, password: password
  FactoryBot.create :authentication, user: user, provider: 'identity', uid: identity.uid

  user
end

def newflow_reauthenticate_user(email, password)
  wait_for_animations
  wait_for_ajax
  expect(page.current_path).to eq(reauthenticate_form_path)
  expect(find('#login_form_email').value).to eq(email) # email should be pre-populated
  fill_in('login_form_password', with: password)
  screenshot!
  find('[type=submit]').click
  wait_for_animations
end

def strip_html(text)
  ActionView::Base.full_sanitizer.sanitize(text)
end

def newflow_complete_add_password_screen(password=nil)
  password ||= 'Passw0rd!'
  fill_in(t(:"login_signup_form.password_label"), with: password)
  find('#login-signup-form').click
  wait_for_animations
  find('[type=submit]').click
  expect(page).to have_content(t :"login_signup_form.profile_newflow_page_header")
end

def expect_newflow_profile_page
  expect(page).to have_no_missing_translations
  expect(page).to have_current_path profile_path
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
