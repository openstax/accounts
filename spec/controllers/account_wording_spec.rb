require 'rails_helper'

# OpenStax doesn't say "adoption" to the people who use these pages; it is an
# internal metric name. Admin screens keep it.
RSpec.describe AccountController, type: :controller do
  render_views

  def visible_text(html)
    doc = Nokogiri::HTML(html)
    doc.css('script, style').each(&:remove)
    doc.text
  end

  let(:user) { FactoryBot.create(:user, :terms_agreed, role: :instructor, first_name: 'Rita', last_name: 'Instructor') }

  before do
    controller.sign_in! user
    Adoption.create!(salesforce_id: 'SF_WORDING', user: user, confirmation_type: 'OpenStax Confirmed Adoption',
                     rollover_status: false, school_year: SchoolYear.current, students: 415, salesforce_book_id: nil)
    AdoptionReport.create!(user: user, book_title: 'College Physics', salesforce_book_name: 'College Physics',
                           school_year: SchoolYear.current, source: 'books_modal', status: 'using', students: 120)
  end

  %i[overview books impact profile].each do |page|
    it "never says adoption on the #{page} page" do
      get page
      expect(visible_text(response.body)).not_to match(/adoption/i)
    end
  end

  it 'never says adoption on the impact page for an instructor with nothing reported' do
    Adoption.delete_all
    AdoptionReport.delete_all
    get :impact
    expect(visible_text(response.body)).not_to match(/adoption/i)
  end

  it 'never says adoption in the report modal' do
    get :books
    html = controller.view_context.render(partial: 'shared/report_adoption_modal')
    expect(visible_text(html)).not_to match(/adoption/i)
    expect(visible_text(html)).to include('Tell us which books you use')
  end
end
