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

      it 'thanks the instructor with the books and students added, shown as pending' do
        year = SchoolYear.current
        post :create, params: { books: [row(school_year: year, students: '120'),
                                        row(name: 'College Physics', school_year: year, students: '45')] }

        expect(flash[:notice]).to eq(
          'Thank you. You added 2 books and 165 students to your impact. ' \
          'This shows now as pending, and joins your totals once we confirm it.'
        )
      end

      it 'does not call a report for another school year pending' do
        post :create, params: { books: [row(school_year: '2020 - 21')] }

        expect(flash[:notice]).to eq(
          'Thank you. Your report is saved and will count in your totals once we confirm it.'
        )
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

  describe '#book_status' do
    let(:user) { FactoryBot.create(:user, :terms_agreed, role: :instructor) }
    let(:saved_book) { UserBook.create!(user: user, book: Book.create!(book_uuid: SecureRandom.uuid, title: 'Introduction to Sociology 3e')) }
    let(:other_book) { UserBook.create!(user: user, book: Book.create!(book_uuid: SecureRandom.uuid, title: 'Mystery Book')) }

    before do
      allow(controller).to receive(:newflow_authenticate_user!).and_return(true)
      allow(controller).to receive(:current_user).and_return(user)
    end

    %w[considering browsing].each do |answer|
      it "saves #{answer} as a local answer for this school year, never pushed" do
        expect(PushAdoptionReports).not_to receive(:perform_later)

        expect { post :book_status, params: { id: saved_book.id, status: answer } }.to change { AdoptionReport.count }.by(1)

        expect(AdoptionReport.last).to have_attributes(
          user: user, status: answer, source: 'books_status', surface: 'books', school_year: SchoolYear.current,
          book_title: 'Introduction to Sociology 3e', salesforce_book_name: 'Sociology', salesforce_pushed_at: nil
        )
        expect(response).to redirect_to(account_books_path)
        expect(AdoptionReport.pushable).to be_empty
      end
    end

    it 'enqueues the book interest push as an add for a considering answer' do
      expect(PushBookInterest).to receive(:perform_later).with(user: user, add: ['Sociology'])

      post :book_status, params: { id: saved_book.id, status: 'considering' }
    end

    it 'lists the book in the interests right away' do
      allow(PushBookInterest).to receive(:perform_later)
      user.update!(which_books: 'Astronomy')

      post :book_status, params: { id: saved_book.id, status: 'considering' }

      expect(user.reload.which_books).to eq('Astronomy;Sociology')
    end

    it 'leaves the interests alone for just looking' do
      user.update!(which_books: 'Astronomy')

      post :book_status, params: { id: saved_book.id, status: 'browsing' }

      expect(user.reload.which_books).to eq('Astronomy')
    end

    it 'does not enqueue the book interest push for just looking' do
      expect(PushBookInterest).not_to receive(:perform_later)

      post :book_status, params: { id: saved_book.id, status: 'browsing' }
    end

    it 'does not enqueue the book interest push when the answer is refused' do
      expect(PushBookInterest).not_to receive(:perform_later)

      post :book_status, params: { id: saved_book.id, status: 'using' }
    end

    it 'changes an earlier answer on the same row' do
      post :book_status, params: { id: saved_book.id, status: 'considering' }

      expect { post :book_status, params: { id: saved_book.id, status: 'browsing' } }.not_to change { AdoptionReport.count }

      expect(AdoptionReport.last.status).to eq('browsing')
    end

    it 'saves a book that is not in the catalog by title' do
      post :book_status, params: { id: other_book.id, status: 'browsing' }
      post :book_status, params: { id: other_book.id, status: 'considering' }

      expect(AdoptionReport.where(book_title: 'Mystery Book').pluck(:status, :salesforce_book_name)).to eq([['considering', nil]])
    end

    it 'never downgrades a using report' do
      AdoptionReport.create!(user: user, book_title: 'Introduction to Sociology 3e', salesforce_book_name: 'Sociology',
                             school_year: SchoolYear.current, status: 'using', source: 'books_modal', how_using: how_using)

      post :book_status, params: { id: saved_book.id, status: 'browsing' }

      expect(AdoptionReport.last.status).to eq('using')
    end

    it 'refuses an unknown status and another user\'s saved book' do
      stranger_book = UserBook.create!(user: FactoryBot.create(:user), book: Book.create!(book_uuid: SecureRandom.uuid, title: 'Theirs'))

      expect { post :book_status, params: { id: saved_book.id, status: 'using' } }.not_to change { AdoptionReport.count }
      expect { post :book_status, params: { id: stranger_book.id, status: 'browsing' } }.not_to change { AdoptionReport.count }
      expect(flash[:alert]).to eq("We couldn't save that answer. Please try again.")
    end

    it 'turns a considering answer into a pushable using report when the modal is submitted' do
      post :book_status, params: { id: saved_book.id, status: 'considering' }
      expect(AdoptionReport.pushable).to be_empty

      expect {
        post :create, params: { books: [{ name: 'Sociology', school_year: SchoolYear.current, how_using: how_using, students: '30' }] }
      }.not_to change { AdoptionReport.count }

      expect(AdoptionReport.last).to have_attributes(status: 'using', source: 'books_modal', students: 30)
      expect(AdoptionReport.pushable.count).to eq(1)
    end
  end
end
