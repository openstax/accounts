require 'rails_helper'

feature 'Admin adoption reviews page', js: true do
  before(:each) do
    create_admin_user
    visit '/'
    complete_newflow_log_in_screen('admin', 'password')
    wait_for_successful_log_in
  end

  let(:instructor) { FactoryBot.create(:user, :terms_agreed, role: 'instructor', first_name: 'Ida', last_name: 'Teacher') }

  def create_report(overrides = {})
    AdoptionReport.create!({
      user: instructor, book_title: 'Biology 2e', salesforce_book_name: 'Biology', school_year: '2026 - 27',
      status: 'using', source: 'books_modal', surface: 'books', students: 5000,
      how_using: AdoptionReport::HOW_USING_OPTIONS.first
    }.merge(overrides))
  end

  scenario 'approving a held report moves it to the Approved tab' do
    report = create_report

    visit admin_adoption_reviews_path
    expect(page).to have_css('#adoption-reviews', text: 'Biology 2e')
    click_button 'Approve'

    expect(page).to have_text('Approved. It will go to Salesforce')
    expect(report.reload.review_status).to eq 'approved'
    click_link 'Approved'
    expect(page).to have_css('#adoption-reviews', text: 'Biology 2e')
  end

  scenario 'changing the count and approving' do
    report = create_report

    visit admin_adoption_reviews_path
    fill_in 'students', with: '600'
    click_button 'Change count and approve'

    expect(page).to have_text('Count changed to 600 and approved.')
    expect(report.reload.students).to eq 600
  end

  scenario 'the nav links to the page' do
    visit admin_users_path
    click_link 'Adoption Reviews'
    expect(page).to have_current_path(admin_adoption_reviews_path)
  end
end
