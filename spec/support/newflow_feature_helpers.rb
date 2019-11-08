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
  fill_in 'login_form_email', with: username_or_email
  expect(page).to have_no_missing_translations

  fill_in('login_form_password', with: password)
  expect(page).to have_no_missing_translations
  screenshot!
  click_button(I18n.t(:"login_signup_form.continue_button"))
  expect(page).to have_no_missing_translations
end
