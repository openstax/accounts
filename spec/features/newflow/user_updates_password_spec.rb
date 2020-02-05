require 'rails_helper'

feature 'User updates password on profile screen', js: true do
  before(:each) do
    turn_on_feature_flag

    @user = create_user('user')
    visit '/'
    newflow_log_in_user('user', 'password')
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
    find('[data-provider=identity] .add--newflow').click

    screenshot!
    newflow_complete_add_password_screen
    screenshot!
    expect(page).to have_no_missing_translations
    expect(page).to have_content(t(:"login_signup_form.how_you_log_in"))
    expect(page).to have_css('[data-provider=facebook]')
    expect(page).to have_css('[data-provider=identity]')
  end

  xscenario "changes existing" do
    find('[data-provider=identity] .edit').click
    complete_reset_password_screen
    complete_reset_password_success_screen
    expect(page).to have_no_missing_translations
    expect(page).to have_content(
      ActionView::Base.full_sanitizer.sanitize t(:"users.edit.how_you_sign_in_html")
    )
    expect(page).to have_css('[data-provider=identity]')
  end

  xscenario "deletes password" do
    FactoryBot.create :authentication, user: @user, provider: 'facebook'
    visit '/profile'
    expect(@user.reload.identity).to be_present
    expect(@user.authentications.reload.count).to eq 2
    expect(page).to have_css('[data-provider=identity]')
    # find('[data-provider=identity] .delete').click
    find('[data-provider=identity] .delete--newflow').click
    find('.confirm-dialog-btn-confirm').click
    expect(page).to have_no_css('[data-provider=identity]')
    expect(@user.reload.identity).to be_nil
    expect(@user.authentications.reload.count).to eq 1
  end
end
