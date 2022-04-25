require 'rails_helper'

feature 'Confirm email address', js: true do
  background do
    @email = Faker::Internet.email
    @user = create_user @email
  end

  scenario 'successfully' do
    visit '/confirm?code=1111'
    expect(page).to have_content(I18n.t :'contact_infos.confirm.page_heading.success')
    expect(page).to have_content(I18n.t :'contact_infos.confirm.you_may_now_close_this_window')
  end

  scenario 'without a confirmation code' do
    visit '/confirm'
    expect(page).to have_no_content('Alert: no_contact_info_for_code')
    expect(page).to have_content(I18n.t :'contact_infos.confirm.page_heading.error')
    expect(page).to have_content(I18n.t :'contact_infos.confirm.verification_code_not_found')
  end

  scenario 'with unmatched confirmation code' do
    visit '/confirm?code=1234'
    expect(page).to have_no_content('Alert: no_contact_info_for_code')
    expect(page).to have_content(I18n.t :'contact_infos.confirm.page_heading.error')
    expect(page).to have_content(I18n.t :'contact_infos.confirm.verification_code_not_found')
  end

  context 'when another user has the email' do
    scenario 'cannot create duplicate email' do
      expect {
        create_user @email
      }.to raise_error(ActiveRecord::RecordInvalid, /already been taken/)
    end
  end
end
