require 'rails_helper'

require_relative './adding_and_resetting_password_from_profile'

feature 'User adds password', js: true do
  before do
    turn_on_student_feature_flag
  end

  it_behaves_like 'adding and resetting password from profile', :add

  scenario 'without identity – form to create password is rendered' do
    @user = create_user('user', 'password', terms_agreed: true)
    @login_token = generate_login_token_for 'user'
    @user.identity.destroy
    visit change_password_form_path(token: @login_token)
    expect(page).to have_content(t(:"login_signup_form.setup_your_new_password"))
  end
end
