require 'spec_helper'

feature 'User signs into admin created account', js: true do

  scenario 'a user signs into an account that is waiting for them', js: true do


    new_user = FindOrCreateUnclaimedUser.call(
      email:'unclaimeduser@example.com', username: 'therulerofallthings',
      password: "apassword", password_confirmation: "apassword"
    ).outputs.user
    expect(new_user.reload.state).to eq("unclaimed")

    with_forgery_protection do
      create_application
      visit_authorize_uri
      expect(page).to have_content("Sign in to #{@app.name} with your one OpenStax account!")

      fill_in 'Username', with: 'therulerofallthings'
      fill_in 'Password', with: 'apassword'
      click_button 'Sign in'

      expect(page).to have_content('Alert: Your password has expired')

    end

  end

end
