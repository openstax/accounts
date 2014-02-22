def create_user username, password='password'
  return if User.find_by_username(username).present?
  user = FactoryGirl.create :user_with_person, username: username
  identity = FactoryGirl.create :identity, user: user, password: password
  FactoryGirl.create :authentication, provider: 'identity', uid: identity.id.to_s, user: user
  return user
end

def create_admin_user
  user = create_user 'admin'
  user.is_administrator = true
  user.save
end

def login_as username, password='password'
  fill_in 'Username', with: username
  fill_in 'Password', with: password
  click_button 'Sign in'
end

def create_new_application
  click_link 'New Application'
  fill_in 'Name', with: 'example'
  fill_in 'Redirect uri', with: 'http://localhost/'
  check 'Trusted?'
  click_button 'Submit'
end
