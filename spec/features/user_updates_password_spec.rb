require 'rails_helper'

feature 'User updates password on profile screen', js: true do
  before(:each) do
    @user = create_user('user')
    visit '/'
    complete_login_username_or_email_screen('user')
    complete_login_password_screen('password')
    expect_profile_page
  end

  scenario "adds one" do
    # Get rid of password (have to add another auth first so things don't freak out)
    FactoryGirl.create :authentication, user: @user, provider: 'facebook'
    @user.authentications.where(provider: 'identity').destroy_all
    @user.identity.destroy
    @user.authentications(true)
    @user.identity(true)
    visit '/profile'

    find('#enable-other-sign-in').click
    wait_for_animations # wait for slide-down effect
    find('[data-provider=identity] .add').click
    complete_add_password_screen
    complete_add_password_success_screen
    expect(page).to have_no_missing_translations
    expect(page.html).to include(t :"users.edit.how_you_sign_in_html")
    expect(page).to have_css('[data-provider=facebook]')
    expect(page).to have_css('[data-provider=identity]')
  end

  scenario "changes existing" do
    find('[data-provider=identity] .edit').click
    complete_reset_password_screen
    complete_reset_password_success_screen
    expect(page).to have_no_missing_translations
    expect(page.html).to include(t :"users.edit.how_you_sign_in_html")
    expect(page).to have_css('[data-provider=identity]')
  end
end
