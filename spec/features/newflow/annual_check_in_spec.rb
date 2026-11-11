require 'rails_helper'

feature 'annual instructor check-in', js: true do
  include ActiveSupport::Testing::TimeHelpers

  let(:today) { Time.zone.local(2025, 11, 15, 12) }

  around { |example| travel_to(today) { example.run } }

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

    expect(page).to have_content('Thank you. You counted 1 book and 75 students')
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

  context 'in the spring window' do
    let(:today) { Time.zone.local(2026, 2, 10, 12) }

    scenario 'an instructor who reported in the fall gets the spring card, prefilled, and it goes away' do
      AdoptionReport.create!(
        user: user, book_title: 'College Physics', school_year: SchoolYear.current,
        source: 'check_in', status: 'using', students: 60, how_using: how_using
      )
      user.update_column(:check_in_completed_at, Time.zone.local(2025, 10, 1))

      newflow_log_in_user('instructor@openstax.org', 'password')
      wait_for_successful_log_in

      visit(account_overview_path)

      within('#annual-check-in') do
        expect(page).to have_content('New term. Still teaching with these books?')
        expect(page).to have_content('Spring classes count toward 2025 - 26.')
        expect(page).to have_field('Students this school year (fall and spring together)', with: '60')
        expect(page).to have_content('An estimate is fine.', count: 2)

        within(find('fieldset', text: 'College Physics')) do
          fill_in('Students this school year (fall and spring together)', with: '90')
          choose('Using this year')
        end
        click_button('Confirm')
      end

      expect(page).to have_content('fall and spring together')
      expect(page).to have_no_css('#annual-check-in')
      expect(AdoptionReport.find_by!(user: user, book_title: 'College Physics', school_year: SchoolYear.current))
        .to have_attributes(students: 90)
    end
  end
end
