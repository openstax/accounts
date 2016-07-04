require 'rails_helper'

feature 'Confirm email address', js: true do
  background do
    user = create_user 'user'
    create_email_address_for user, 'user@example.com', '1111'
  end

  scenario 'successfully' do
    visit '/confirm?code=1111'
    expect(page).to have_no_missing_translations
    expect(page).to have_content(t :"contact_infos.confirm.page_heading.success")
    expect(page).to have_content(t :"contact_infos.confirm.you_may_now_close_this_window")
  end

  scenario 'without a confirmation code' do
    visit '/confirm'
    expect(page).to have_no_missing_translations
    expect(page).to_not have_content('Alert: no_contact_info_for_code')
    expect(page).to have_content(t :"routines.confirm_by_code.unable_to_verify_address")
    expect(page).to have_content(t :"contact_infos.confirm.verification_code_not_found")
  end

  scenario 'with unmatched confirmation code' do
    visit '/confirm?code=1234'
    expect(page).to have_no_missing_translations
    expect(page).to_not have_content('Alert: no_contact_info_for_code')
    expect(page).to have_content(t :"routines.confirm_by_code.unable_to_verify_address")
    expect(page).to have_content(t :"contact_infos.confirm.verification_code_not_found")
  end
end
