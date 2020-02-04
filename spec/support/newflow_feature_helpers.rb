# Creates a verified user, an email address, and a password
def create_newflow_user(email, password='password', terms_agreed=nil, confirmation_code=nil)
  terms_agreed_option = (terms_agreed.nil? || terms_agreed) ?
                          :terms_agreed :
                          :terms_not_agreed

  # return if User.find_by_username(username).present?

  user = FactoryBot.create :user, terms_agreed_option
  FactoryBot.create(:email_address, user: user, value: email,
                     confirmation_code: confirmation_code,
                     verified: confirmation_code.nil?)
  identity = FactoryBot.create :identity, user: user, password: password
  authentication = FactoryBot.create :authentication, user: user,
                                                       provider: 'identity',
                                                       uid: identity.uid
  return user
end

def newflow_log_in_user(username_or_email, password)
  visit(newflow_login_path) unless page.current_url == newflow_login_path
  fill_in 'login_form_email', with: username_or_email
  expect(page).to have_no_missing_translations

  fill_in('login_form_password', with: password)
  expect(page).to have_no_missing_translations
  screenshot!
  click_button(I18n.t(:"login_signup_form.continue_button"))
  wait_for_animations
  wait_for_ajax
  screenshot!
  expect(page).to have_no_missing_translations
end

def fill_in_signup_form(email: nil, password: nil, first_name: nil, last_name: nil, newsletter: false)
  fill_in('signup_email', with: email) if email
  fill_in('signup_password', with: password) if password
  fill_in('signup_first_name', with: password) if first_name
  fill_in('signup_last_name', with: password) if last_name
  check('signup_newsletter') if newsletter
  check('signup_terms_accepted')
end


def strip_html(text)
  ActionView::Base.full_sanitizer.sanitize(text)
end

def turn_on_feature_flag # TODO: move into general spec helpers, not just feature spec helpers
  Settings::Db.store.newflow_feature_flag = true
end

def expect_sign_up_welcome_tab
  expect(page).to have_no_missing_translations
  expect(page).to have_content(t :"login_signup_form.welcome_page_header")
end

def newflow_click_sign_up(role:)
  click_on (t :"login_signup_form.sign_up") # unless already there
  expect(page).to have_no_missing_translations
  expect(page).to have_content(t :"login_signup_form.welcome_page_header")
  find(".join-as__role.#{role}").click
end
