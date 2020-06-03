require 'rails_helper'

require_relative './add_reset_password_shared_examples'

feature 'User adds password', js: true do

  it_behaves_like "add_reset_password_shared_examples", :add

  scenario 'without identity gets redirected to add password' do
    @user = create_user 'user'
    @login_token = generate_login_token_for 'user'
    @user.identity.destroy
    visit password_reset_path(token: @login_token)
    expect(page).to have_current_path password_add_path
  end

end
