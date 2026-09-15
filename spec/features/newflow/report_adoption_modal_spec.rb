require 'rails_helper'

feature 'report an adoption modal', js: true do
  let!(:biology) { Book.create!(book_uuid: SecureRandom.uuid, title: 'Biology 2e') }
  let!(:physics) { Book.create!(book_uuid: SecureRandom.uuid, title: 'College Physics') }

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

    expect {
      click_button('Submit report')
      expect(page).to have_content("Thanks — your report helps us measure OpenStax's impact.", wait: 5)
    }.to change { AdoptionReport.count }.by(2)
  end
end
