require 'rails_helper'

feature 'User updates password on profile screen', js: true do
  before(:each) do
    turn_on_student_feature_flag

    @user = create_user('user', 'password', terms_agreed: true)
    @user.update!(role: User::STUDENT_ROLE)
    visit '/'
    complete_newflow_log_in_screen('user', 'password')
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
end
