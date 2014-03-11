def create_user(username, password='password')
  return if User.find_by_username(username).present?
  user = FactoryGirl.create :user_with_person, :terms_agreed, username: username
  identity = FactoryGirl.create :identity, user: user, password: password
  FactoryGirl.create :authentication, provider: 'identity', uid: identity.id.to_s, user: user
  return user
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

def create_nonlocal_user(username)
  auth_data = {info: {nickname: username}, provider: 'facebook'}
  result = CreateUserFromOmniauth.call(auth_data)
  raise "create_nonlocal_user for #{username} failed" if result.errors.any?
  User.find_by_username(username)
end

def login_as username, password='password'
  fill_in 'Username', with: username
  fill_in 'Password', with: password
  click_button 'Sign in'
end

def create_new_application(trusted = false)
  click_link 'New Application'
  fill_in 'Name', with: 'example'
  fill_in 'Redirect uri', with: 'http://localhost/'
  check 'Trusted?' if trusted
  click_button 'Submit'
end

def create_email_address_for(user, email_address, confirmation_code=nil)
  FactoryGirl.create(:email_address, user: user, value: email_address,
                     confirmation_code: confirmation_code)
end

def generate_reset_code_for(username)
  user = User.find_by_username(username)
  identity = user.identity
  identity.generate_reset_code
  identity.reset_code
end

def generate_expired_reset_code_for(username)
  one_year_ago = 1.year.ago
  DateTime.stub(:now).and_return(one_year_ago)
  reset_code = generate_reset_code_for username
  DateTime.unstub(:now)
  reset_code
end

def password_reset_email_sent?(user)
  user_emails = user.contact_infos.email_addresses.verified
  mail = ActionMailer::Base.deliveries.last
  expect(mail.to.length).to eq(1)
  expect(user_emails.collect {|e| e.value}).to include(mail.to[0])
  expect(mail.from).to eq(['noreply@openstax.org'])
  expect(mail.subject).to eq('[OpenStax] Reset your password')
  expect(mail.body.encoded).to include("Hi #{user.username},")
  @reset_link = "/reset_password?code=#{user.identity.reset_code}"
  expect(mail.body.encoded).to include("http://nohost#{@reset_link}")
end

def create_application
  @app = FactoryGirl.create(:doorkeeper_application, :trusted,
                           redirect_uri: 'http://www.example.com/callback')
  token = FactoryGirl.create(:doorkeeper_access_token,
                             application: @app, resource_owner_id: nil)
  @app
end

def with_forgery_protection
  begin
    ActionController::Base.any_instance.stub(:allow_forgery_protection).and_return(true)
    yield if block_given?
  ensure
    ActionController::Base.any_instance.unstub(:allow_forgery_protection)
  end
end

def visit_authorize_uri
  visit "/oauth/authorize?redirect_uri=#{@app.redirect_uri}&response_type=code&client_id=#{@app.uid}"
end

def app_callback_url
  /^#{@app.redirect_uri}\?code=.+$/
end
