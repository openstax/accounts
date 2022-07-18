require 'rails_helper'

feature 'Confirm email address', js: true do
  background do
    user = create_user 'user'
    create_email_address_for user, 'user@example.com', '1111'
  end

  scenario 'successfully' do
    visit '/confirm?code=1111'
    expect(page).to have_content(t :"contact_infos.confirm.page_heading.success")
    expect(page).to have_content(t :"contact_infos.confirm.you_may_now_close_this_window")
  end

  scenario 'without a confirmation code' do
    visit '/confirm'
    expect(page).to have_no_content('Alert: no_contact_info_for_code')
    expect(page).to have_content(t :"contact_infos.confirm.page_heading.error")
    expect(page).to have_content(t :"contact_infos.confirm.verification_code_not_found")
  end

  scenario 'with unmatched confirmation code' do
    visit '/confirm?code=1234'
    expect(page).to have_no_content('Alert: no_contact_info_for_code')
    expect(page).to have_content(t :"contact_infos.confirm.page_heading.error")
    expect(page).to have_content(t :"contact_infos.confirm.verification_code_not_found")
  end

  context 'when another user has the email' do
    scenario 'cannot create duplicate email' do
      expect {
        create_email_address_for(create_user('other_user'), 'user@example.com', '989188')
      }.to raise_error(ActiveRecord::RecordInvalid, /already been taken/)
    end
  end
end
