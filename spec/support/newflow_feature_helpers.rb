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

def newflow_complete_add_password_screen(password=nil)
  password ||= 'Passw0rd!'
  fill_in(t(:"login_signup_form.password_label"), with: password)
  find('#login-signup-form').click
  wait_for_animations
  find('[type=submit]').click
  expect(page).to have_content(t :"login_signup_form.profile_newflow_page_header")
end

def external_public_url
  capybara_url(external_app_for_specs_path) + '/public'
end
