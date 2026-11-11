require 'rails_helper'

feature 'annual instructor check-in', js: true do
  let!(:sociology) { Book.create!(book_uuid: SecureRandom.uuid, title: 'Introduction to Sociology 3e') }
  let!(:physics) { Book.create!(book_uuid: SecureRandom.uuid, title: 'College Physics') }
  let(:how_using) { AdoptionReport::HOW_USING_OPTIONS.second }
  let(:last_year) { SchoolYear.label_for(SchoolYear.base_year_for(Time.zone.today) - 1) }

  let!(:user) do
    instructor = create_newflow_user('instructor@openstax.org', 'password', true, nil, 'instructor')
    instructor.update_column(:created_at, 2.years.ago) # bypass timestamps: simulate an old account
    UserBook.create!(user: instructor, book: sociology)
    UserBook.create!(user: instructor, book: physics)
    AdoptionReport.create!(
      user: instructor, book_title: 'College Physics', school_year: last_year,
      source: 'books_modal', students: 75, how_using: how_using
    )
    instructor
  end

  before do
    allow_any_instance_of(FetchBookData).to receive(:books_by_subject).and_return([
      { subject_name: 'Science', books: [
        { title: 'College Physics', salesforce_abbreviation: 'College Physics', cover_url: nil }
      ] }
    ])
  end

  scenario 'an instructor answers the card on the overview and the card goes away' do
    newflow_log_in_user('instructor@openstax.org', 'password')
    wait_for_successful_log_in

    visit(account_overview_path)

    within('#annual-check-in') do
      expect(page).to have_content(/annual check-in/i)
      expect(page).to have_content(SchoolYear.current)
      expect(page).to have_field('Students', with: '75')
      expect(page).to have_no_checked_field('Using this year')

      within(find('fieldset', text: 'College Physics')) { choose('Using this year') }
      within(find('fieldset', text: 'Introduction to Sociology 3e')) { choose('Not using') }
      click_button('Confirm')
    end

    expect(page).to have_content(I18n.t('annual_check_in.confirmed_flash'))
    expect(page).to have_current_path(account_overview_path)
    expect(page).to have_no_css('#annual-check-in')

    physics_report = AdoptionReport.find_by!(user: user, book_title: 'College Physics', school_year: SchoolYear.current)
    expect(physics_report).to have_attributes(status: 'using', source: 'check_in', students: 75, how_using: how_using)
    expect(AdoptionReport.find_by!(user: user, book_title: 'Introduction to Sociology 3e')).to have_attributes(status: 'not_using')
    expect(user.reload.check_in_completed_at).to be_present
  end

  scenario 'the card never blocks: profile stays reachable and "Remind me later" hides it' do
    newflow_log_in_user('instructor@openstax.org', 'password')
    wait_for_successful_log_in

    visit(account_profile_path)
    expect(page).to have_current_path(account_profile_path)

    visit(account_overview_path)
    within('#annual-check-in') { click_button('Remind me later') }

    expect(page).to have_content(I18n.t('annual_check_in.dismissed_flash'))
    expect(page).to have_no_css('#annual-check-in')
    expect(user.reload.check_in_dismissed_at).to be_present
  end

  scenario 'the old check-in URL lands on the overview card' do
    newflow_log_in_user('instructor@openstax.org', 'password')
    wait_for_successful_log_in

    visit(account_check_in_path)

    expect(page).to have_current_path(account_overview_path, ignore_query: true)
    expect(page).to have_css('#annual-check-in')
  end
end
