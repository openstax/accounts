require 'rails_helper'

feature 'report an adoption modal', js: true do
  let!(:biology) do
    Book.create!(book_uuid: SecureRandom.uuid, title: 'Biology 2e', salesforce_name: 'Biology', salesforce_book_id: 'a0BBIO')
  end

  before do
    allow_any_instance_of(FetchBookData).to receive(:books_by_subject).and_return([
      { subject_name: 'Science', books: [
        { title: 'Biology 2e', salesforce_abbreviation: 'Biology', cover_url: nil },
        { title: 'College Physics', salesforce_abbreviation: 'College Physics', cover_url: nil }
      ] }
    ])
  end

  let!(:instructor) do
    create_newflow_user('instructor@openstax.org', 'password', true, nil, 'instructor')
  end

  def open_modal
    find('[data-report-adoption-trigger]').click
    expect(page).to have_css('#reportAdoptionModal.in', wait: 5)
    wait_for_animations
  end

  # Rows are numbered by their position, so a removed row can't leave two
  # rows sharing an index (which would silently drop one adoption on POST).
  scenario 'keeps row indexes unique after a row is removed and the modal is reopened' do
    newflow_log_in_user('instructor@openstax.org', 'password')

    visit(account_overview_path)
    wait_for_animations
    wait_for_ajax

    open_modal
    click_button('+ Add another book')
    expect(page).to have_css('[data-report-adoption-row]', count: 2)

    # Drop the original row 0; the survivor must be renumbered back to 0.
    first('[data-report-adoption-row] [data-report-adoption-remove]').click
    expect(page).to have_css('select[name="books[0][name]"]', count: 1)

    find('#reportAdoptionModal button.close').click
    expect(page).to have_no_css('#reportAdoptionModal.in', wait: 5)

    open_modal
    click_button('+ Add another book')

    expect(page).to have_css('select[name="books[0][name]"]', count: 1)
    expect(page).to have_css('select[name="books[1][name]"]', count: 1)

    find('select[name="books[0][name]"]').select('Biology 2e')
    find('select[name="books[1][name]"]').select('College Physics')

    expect(page).to have_select('books[0][how_using]', selected: AdoptionReport::HOW_USING_OPTIONS.first)
    find('select[name="books[1][how_using]"]').select(AdoptionReport::HOW_USING_OPTIONS.last)

    expect {
      click_button('Submit report')
      expect(page).to have_content('Thank you. You added 2 books', wait: 5)
    }.to change { AdoptionReport.count }.by(2)
  end

  scenario 'prefills how the user said they use a book last time and submits the Salesforce abbreviation' do
    Adoption.create!(salesforce_id: 'a0A001', user: instructor, salesforce_book_id: 'a0BBIO',
                     how_using: AdoptionReport::HOW_USING_OPTIONS[1])
    newflow_log_in_user('instructor@openstax.org', 'password')

    visit(account_overview_path)
    wait_for_animations
    open_modal

    find('select[name="books[0][name]"]').select('Biology 2e')
    expect(page).to have_select('books[0][how_using]', selected: AdoptionReport::HOW_USING_OPTIONS[1])

    click_button('Submit report')
    expect(page).to have_content('Thank you. You added 1 book', wait: 5)

    expect(AdoptionReport.last).to have_attributes(
      salesforce_book_name: 'Biology', book_title: 'Biology 2e',
      how_using: AdoptionReport::HOW_USING_OPTIONS[1], surface: 'overview'
    )
  end

  scenario 'preselects the book named by data-report-adoption-book, and clears it for a trigger without one' do
    Adoption.create!(salesforce_id: 'a0A002', user: instructor, salesforce_book_id: 'a0BBIO',
                     how_using: AdoptionReport::HOW_USING_OPTIONS[2])
    newflow_log_in_user('instructor@openstax.org', 'password')

    visit(account_overview_path)
    wait_for_animations
    page.execute_script(<<~JS)
      var plain = document.querySelector('[data-report-adoption-trigger]');
      var withBook = plain.cloneNode(true);
      withBook.setAttribute('data-report-adoption-book', 'Biology');
      withBook.id = 'trigger-with-book';
      plain.parentNode.insertBefore(withBook, plain);
    JS

    find('#trigger-with-book').click
    expect(page).to have_css('#reportAdoptionModal.in', wait: 5)
    wait_for_animations
    expect(page).to have_select('books[0][name]', selected: 'Biology 2e')
    expect(page).to have_select('books[0][how_using]', selected: AdoptionReport::HOW_USING_OPTIONS[2])
    expect(page).to have_css('[data-report-adoption-summary-subtext]', text: 'Across 1 books')

    find('#reportAdoptionModal button.close').click
    expect(page).to have_no_css('#reportAdoptionModal.in', wait: 5)

    find('[data-report-adoption-trigger]:not(#trigger-with-book)', match: :first).click
    expect(page).to have_css('#reportAdoptionModal.in', wait: 5)
    wait_for_animations
    expect(page).to have_select('books[0][name]', selected: 'Select a book')
  end
end
