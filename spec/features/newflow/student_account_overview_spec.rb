require 'rails_helper'

feature 'student account overview', js: true do
  let!(:school) { FactoryBot.create(:school, name: 'Rice University') }

  let!(:student) do
    user = create_newflow_user('student@openstax.org', 'password', true, nil, 'student')
    user.update!(first_name: 'Jordan', school: school)
    user
  end

  let!(:instructor) do
    FactoryBot.create(:user, role: :instructor, faculty_status: :confirmed_faculty, school: school,
                              first_name: 'Sarah', last_name: 'Delgado')
  end

  let!(:book) do
    Book.create!(book_uuid: SecureRandom.uuid, title: 'Biology 2e',
                  html_url: 'https://openstax.org/details/books/biology-2e')
  end

  before { UserBook.create!(user: student, book: book) }

  scenario 'shows the student overview with saved books, and connects to a listed instructor' do
    newflow_log_in_user('student@openstax.org', 'password')

    visit(account_overview_path)
    wait_for_animations
    wait_for_ajax

    expect(page).to have_current_path(account_overview_path)
    expect(page).to have_content('Welcome back, Jordan')
    expect(page).to have_content('Student')
    expect(page).to have_content('School verified')
    expect(page).to have_content('Biology 2e')
    expect(page).to have_content('Tell us who teaches your class')
    expect(page).to have_content('It does not message your instructor, connect your accounts, or change your saved books.')

    fill_in('instructor-search-input', with: 'Delg')
    expect(page).to have_css('li', text: 'Sarah Delgado', wait: 5)
    expect(page).to have_content('Rice University')

    # A native Selenium click on this option is flaky in this environment:
    # the dev-only #upper-corner-console (fixed-position, every non-prod
    # page) intermittently overlaps the click coordinates depending on
    # scroll position. Dispatching the mousedown directly exercises the
    # exact same handler (verified to behave identically to a real click)
    # without fighting that unrelated layout quirk.
    page.execute_script(<<~JS)
      var li = document.getElementById('instructor-search-option-0');
      li.dispatchEvent(new MouseEvent('mousedown', { bubbles: true, cancelable: true }));
    JS

    # The autocomplete selection POSTs via fetch (not jQuery), so wait on the
    # status text it renders rather than wait_for_ajax's jQuery.active check.
    expect(page).to have_content('Thanks — we recorded Sarah Delgado as your instructor.', wait: 5)

    connection = InstructorConnection.find_by(student: student)
    expect(connection).to be_present
    expect(connection.instructor).to eq(instructor)
    expect(connection.status).to eq('unverified')
  end

  scenario "captures an instructor via the 'isn't listed' fallback form" do
    newflow_log_in_user('student@openstax.org', 'password')

    visit(account_overview_path)
    wait_for_animations
    wait_for_ajax

    fill_in('instructor-name', with: 'Marcus Delgado')
    fill_in('instructor-school', with: 'University of Houston')
    fill_in('instructor-course', with: 'BIOL 101')

    click_button('Submit instructor information')
    wait_for_animations
    wait_for_ajax

    expect(page).to have_current_path(account_overview_path)

    connection = InstructorConnection.find_by(student: student, instructor_name: 'Marcus Delgado')
    expect(connection).to be_present
    expect(connection.instructor).to be_nil
    expect(connection.school_name).to eq('University of Houston')
    expect(connection.course).to eq('BIOL 101')
    expect(connection.status).to eq('unverified')
  end
end
