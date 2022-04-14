
def log_in_user(username_or_email, password)
  visit(login_path) unless page.current_url == login_url
  fill_in('login_form_email', with: username_or_email).native

  fill_in('login_form_password', with: password)
  wait_for_animations
  wait_for_ajax
  screenshot!
  click_button(I18n.t(:'login_signup_form.continue_button'))
  wait_for_animations
  wait_for_ajax
  screenshot!
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
  fill_in(t(:'login_signup_form.password_label'), with: password)
  find('#login-signup-form').click
  wait_for_animations
  find('[type=submit]').click
  expect(page).to have_content(t :'login_signup_form.profile_newflow_page_header')
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

    [:googlenewflow, :facebooknewflow].each do |provider|
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
