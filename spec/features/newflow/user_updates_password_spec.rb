require 'rails_helper'

feature 'User updates password on profile screen', js: true do
  before(:each) do
    turn_on_student_feature_flag

    @user = create_user('user', 'password', terms_agreed: true)
    @user.update!(role: User::STUDENT_ROLE)
    visit '/'
    complete_newflow_log_in_screen('user', 'password')
  end

  scenario "adds one" do
    # Get rid of password (have to add another auth first so things don't freak out)
    FactoryBot.create :authentication, user: @user, provider: 'facebooknewflow'
    @user.authentications.where(provider: 'identity').destroy_all
    @user.identity.destroy
    @user.authentications.reload
    @user.reload.identity
    visit profile_newflow_path

    screenshot!
    expect(page).not_to have_css('[data-provider=identity]')
    find('#enable-other-sign-in').click
    expect(page).to have_css('[data-provider=identity]')

    screenshot!
    wait_for_animations # wait for slide-down effect
    find('[data-provider=identity] .add--newflow').click

    screenshot!
    newflow_complete_add_password_screen
    screenshot!
    expect(page).to have_no_missing_translations
    expect(page).to have_content(t(:"login_signup_form.how_you_log_in"))

    find('#enable-other-sign-in').click
    expect(page).to have_css('[data-provider=facebooknewflow]')
    expect(page).to have_css('[data-provider=identity]')
  end

  scenario "changes existing" do
    visit profile_newflow_path
    find('[data-provider=identity] .edit--newflow').click
    newflow_complete_add_password_screen
    expect(page).to have_no_missing_translations
    expect(page).to have_content(
      ActionView::Base.full_sanitizer.sanitize t(:"legacy.users.edit.how_you_sign_in_html")
    )
    expect(page).to have_css('[data-provider=identity]')
  end

  scenario "deletes password" do
    FactoryBot.create :authentication, user: @user, provider: 'facebooknewflow'
    visit profile_newflow_path
    expect(@user.reload.identity).to be_present
    expect(@user.authentications.reload.count).to eq 2
    expect(page).to have_css('[data-provider=identity]')
    find('[data-provider=identity] .delete--newflow').click
    find('.confirm-dialog-btn-confirm').click
    expect(page).to have_no_css('[data-provider=identity]')
    expect(@user.reload.identity).to be_nil
    expect(@user.authentications.reload.count).to eq 1
  end
end
