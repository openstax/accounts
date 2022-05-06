require 'rails_helper'

require_relative './adding_and_resetting_password_from_profile'

feature 'User adds password', js: true do
  it_behaves_like 'adding and resetting password from profile', :add

  scenario 'without identity – form to create password is rendered' do
    @user = create_user 'example@openstax.org'
    @login_token = generate_login_token_for @user
    @user.identity.destroy
    visit create_password_form_path(token: @login_token)
    expect(page).to have_content(I18n.t(:'login_signup_form.setup_your_new_password'))
  end
end
