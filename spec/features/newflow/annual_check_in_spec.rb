require 'rails_helper'

feature 'annual instructor check-in', js: true do
  let!(:book) { Book.create!(book_uuid: SecureRandom.uuid, title: 'Intro to Sociology') }

  let!(:user) do
    instructor = create_newflow_user('instructor@openstax.org', 'password', true, nil, 'instructor')
    instructor.update_column(:created_at, 2.years.ago) # bypass timestamps: simulate an old account
    UserBook.create!(user: instructor, book: book)
    instructor
  end

  scenario 'an eligible instructor is gated on account pages, confirms, and lands back with a report created' do
    newflow_log_in_user('instructor@openstax.org', 'password')

    visit(account_overview_path)
    wait_for_animations
    wait_for_ajax

    expect(page).to have_current_path(account_check_in_path)
    expect(page).to have_content(/annual check-in/i)
    expect(page).to have_content('Intro to Sociology')

    fill_in_number_field_for('Intro to Sociology', with: '88')
    click_button(I18n.t('annual_check_in.confirm_button'))
    wait_for_animations
    wait_for_ajax

    expect(page).to have_current_path(account_overview_path)
    expect(page).to have_content(I18n.t('annual_check_in.confirmed_flash'))

    report = AdoptionReport.find_by(user: user, book_title: 'Intro to Sociology')
    expect(report).to be_present
    expect(report.source).to eq('check_in')
    expect(report.students).to eq(88)
    expect(report.school_year).to eq(AdoptionReport.current_school_year_label)

    user.reload
    expect(user.check_in_completed_at).to be_present

    # The gate no longer interposes once the check-in is complete for the year.
    visit(account_overview_path)
    expect(page).to have_current_path(account_overview_path)
  end

  scenario 'an instructor can snooze the check-in and pick up where they left off' do
    newflow_log_in_user('instructor@openstax.org', 'password')

    visit(account_profile_path)
    wait_for_animations
    wait_for_ajax
    expect(page).to have_current_path(account_check_in_path)

    click_button(I18n.t('annual_check_in.dismiss_button'))
    wait_for_animations
    wait_for_ajax

    expect(page).to have_current_path(account_profile_path)
    expect(user.reload.check_in_dismissal_count).to eq(1)
  end

  def fill_in_number_field_for(_book_title, with:)
    find('input[type="number"]').set(with)
  end
end
