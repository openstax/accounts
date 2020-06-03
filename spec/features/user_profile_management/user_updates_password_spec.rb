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
    FactoryBot.create :authentication, user: @user, provider: 'facebook'
    @user.authentications.where(provider: 'identity').destroy_all
    @user.identity.destroy
    @user.authentications.reload
    @user.reload.identity
    visit '/profile'

    screenshot!
    find('#enable-other-sign-in').click

    screenshot!
    wait_for_animations # wait for slide-down effect
    find('[data-provider=identity] .add').click

    screenshot!
    complete_add_password_screen
    screenshot!
    complete_add_password_success_screen
    screenshot!
    expect(page).to have_no_missing_translations
    expect(page).to have_content(
      ActionView::Base.full_sanitizer.sanitize 'How you log in'
    )
    expect(page).to have_css('[data-provider=facebook]')
    expect(page).to have_css('[data-provider=identity]')
  end

  scenario "changes existing" do
    find('[data-provider=identity] .edit').click
    complete_reset_password_screen
    complete_reset_password_success_screen
    expect(page).to have_no_missing_translations
    expect(page).to have_content(
      ActionView::Base.full_sanitizer.sanitize t(:"legacy.users.edit.how_you_sign_in_html")
    )
    expect(page).to have_css('[data-provider=identity]')
  end

  scenario "deletes password" do
    FactoryBot.create :authentication, user: @user, provider: 'facebook'
    visit '/profile'
    expect(@user.reload.identity).to be_present
    expect(@user.authentications.reload.count).to eq 2
    expect(page).to have_css('[data-provider=identity]')
    find('[data-provider=identity] .delete').click
    find('.confirm-dialog-btn-confirm').click
    expect(page).to have_no_css('[data-provider=identity]')
    expect(@user.reload.identity).to be_nil
    expect(@user.authentications.reload.count).to eq 1
  end
end
