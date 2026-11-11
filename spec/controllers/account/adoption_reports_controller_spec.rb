require 'rails_helper'

RSpec.describe Account::AdoptionReportsController, type: :controller do
  let(:user) { FactoryBot.create(:user, :terms_agreed) }
  let(:how_using) { AdoptionReport::HOW_USING_OPTIONS.first }

  before do
    allow_any_instance_of(FetchBookData).to receive(:books_by_subject).and_return([
      { subject_name: 'Social Sciences', books: [
        { title: 'Introduction to Sociology 3e', salesforce_abbreviation: 'Sociology', cover_url: nil }
      ] },
      { subject_name: 'Science', books: [
        { title: 'College Physics', salesforce_abbreviation: 'College Physics', cover_url: nil }
      ] }
    ])
  end

  def row(overrides = {})
    { name: 'Sociology', school_year: '2025 - 26', how_using: how_using, students: '10' }.merge(overrides)
  end

  describe '#create' do
    context 'when not signed in' do
      it 'redirects to login instead of creating a report' do
        expect { post :create, params: { books: [row] } }.not_to change { AdoptionReport.count }

        expect(response).to redirect_to(newflow_login_path)
      end
    end

    context 'when signed in' do
      before do
        allow(controller).to receive(:newflow_authenticate_user!).and_return(true)
        allow(controller).to receive(:current_user).and_return(user)
      end

      it 'creates a report per valid row, storing the CMS title and the Salesforce abbreviation' do
        expect(PushAdoptionReports).to receive(:perform_later).with(user: user)

        expect {
          post :create, params: { books: [row(students: '120'), row(name: 'College Physics', students: '45')] }
        }.to change { AdoptionReport.count }.by(2)

        report = AdoptionReport.find_by(salesforce_book_name: 'Sociology')
        expect(report).to have_attributes(
          user: user, book_title: 'Introduction to Sociology 3e', school_year: '2025 - 26', students: 120,
          status: 'using', source: 'books_modal', how_using: how_using, surface: 'books'
        )
        expect(response).to redirect_to(account_books_path)
        expect(flash[:notice]).to be_present
      end

      it 'accepts the indexed hash submitted by the browser form and returns to its source page' do
        expect {
          post :create, params: {
            return_to: account_impact_path(view: 'current'),
            books: { '0' => row(students: '120'), '1' => row(name: 'College Physics', students: '45') }
          }
        }.to change { AdoptionReport.count }.by(2)

        expect(response).to redirect_to(account_impact_path(view: 'current'))
        expect(AdoptionReport.pluck(:surface).uniq).to eq(['impact'])
      end

      { overview: :account_overview_path, books: :account_books_path,
        impact: :account_impact_path, check_in: :account_check_in_path }.each do |surface, helper|
        it "records #{surface} as the surface when returning to that page" do
          path = public_send(helper)
          post :create, params: { return_to: path, books: [row] }

          expect(AdoptionReport.last.surface).to eq(surface.to_s)
          expect(response).to redirect_to(path)
        end
      end

      it 'does not redirect to an untrusted return path' do
        post :create, params: { return_to: '//example.com', books: [row] }

        expect(response).to redirect_to(account_books_path)
        expect(AdoptionReport.last.surface).to eq('books')
      end

      it 'skips a book the CMS list does not know' do
        expect {
          post :create, params: { books: [row, row(name: 'Not A Real Book')] }
        }.to change { AdoptionReport.count }.by(1)

        expect(response).to redirect_to(account_books_path)
        expect(flash[:notice]).to be_present
      end

      it 'skips a row whose how_using is not one of the four Salesforce values' do
        expect {
          post :create, params: { books: [row(how_using: 'Because I felt like it'), row(how_using: '')] }
        }.not_to change { AdoptionReport.count }

        expect(flash[:alert]).to be_present
      end

      it "flashes a partial-failure notice and still enqueues the push when some rows can't be saved" do
        expect(PushAdoptionReports).to receive(:perform_later).with(user: user)

        expect {
          post :create, params: { books: [row, row(name: 'College Physics', students: '-5')] }
        }.to change { AdoptionReport.count }.by(1)

        expect(flash[:alert]).to be_present
        expect(flash[:notice]).to be_blank
      end

      it 'does not enqueue the push when no rows can be saved' do
        expect(PushAdoptionReports).not_to receive(:perform_later)

        expect {
          post :create, params: { books: [row(students: '-5')] }
        }.not_to change { AdoptionReport.count }

        expect(flash[:alert]).to be_present
      end

      it 'links the report to an existing Book by title when one matches' do
        book = Book.create!(book_uuid: SecureRandom.uuid, title: 'Introduction to Sociology 3e')

        post :create, params: { books: [row] }

        expect(AdoptionReport.last.book).to eq(book)
      end

      it 'upserts on user, abbreviation and school year' do
        post :create, params: { books: [row(students: '10')] }

        expect {
          post :create, params: {
            books: [row(students: '25', how_using: AdoptionReport::HOW_USING_OPTIONS.last)]
          }
        }.not_to change { AdoptionReport.count }

        expect(AdoptionReport.last).to have_attributes(students: 25, how_using: AdoptionReport::HOW_USING_OPTIONS.last)
      end

      it 'queues a pushed report to be sent again when its count or use changes' do
        post :create, params: { books: [row(students: '10')] }
        AdoptionReport.last.update!(salesforce_pushed_at: 1.day.ago)

        post :create, params: { books: [row(students: '10')] }
        expect(AdoptionReport.last.salesforce_pushed_at).to be_present

        post :create, params: { books: [row(students: '30')] }
        expect(AdoptionReport.last.salesforce_pushed_at).to be_nil
      end

      it 'adopts a title-only row saved before abbreviations existed instead of duplicating it' do
        legacy = user.adoption_reports.create!(
          book_title: 'Introduction to Sociology 3e', school_year: '2025 - 26', source: 'check_in'
        )

        expect { post :create, params: { books: [row] } }.not_to change { AdoptionReport.count }

        expect(legacy.reload).to have_attributes(salesforce_book_name: 'Sociology', source: 'books_modal')
      end

      it 'skips fully blank rows' do
        expect {
          post :create, params: { books: [{ name: '', school_year: '', students: '' }, row] }
        }.to change { AdoptionReport.count }.by(1)
      end

      it 'rejects a submission with no valid rows and redirects with an error' do
        expect {
          post :create, params: { books: [{ name: '', school_year: '', students: '' }] }
        }.not_to change { AdoptionReport.count }

        expect(response).to redirect_to(account_books_path)
        expect(flash[:alert]).to be_present
      end

      it 'rejects a submission missing the books param entirely' do
        expect { post :create, params: {} }.not_to change { AdoptionReport.count }

        expect(flash[:alert]).to be_present
      end
    end
  end
end
