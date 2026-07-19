require 'rails_helper'

RSpec.describe Account::AdoptionReportsController, type: :controller do
  let(:user) { FactoryBot.create(:user, :terms_agreed) }

  describe '#create' do
    context 'when not signed in' do
      it 'redirects to login instead of creating a report' do
        expect {
          post :create, params: { books: [{ name: 'Test Book', school_year: '2025 - 26', students: '10' }] }
        }.not_to change { AdoptionReport.count }

        expect(response).to redirect_to(newflow_login_path)
      end
    end

    context 'when signed in' do
      before do
        allow(controller).to receive(:newflow_authenticate_user!).and_return(true)
        allow(controller).to receive(:current_user).and_return(user)
      end

      it 'creates an adoption report for each valid row' do
        expect {
          post :create, params: {
            books: [
              { name: 'Intro to Sociology', school_year: '2025 - 26', students: '120' },
              { name: 'College Physics', school_year: '2025 - 26', students: '45' }
            ]
          }
        }.to change { AdoptionReport.count }.by(2)

        report = AdoptionReport.find_by(book_title: 'Intro to Sociology')
        expect(report.user).to eq(user)
        expect(report.school_year).to eq('2025 - 26')
        expect(report.students).to eq(120)
        expect(report.status).to eq('using')
        expect(report.source).to eq('books_modal')

        expect(response).to redirect_to(account_books_path)
        expect(flash[:notice]).to be_present
      end

      it 'links the report to an existing Book by title when one matches' do
        book = Book.create!(book_uuid: SecureRandom.uuid, title: 'Intro to Sociology')

        post :create, params: {
          books: [{ name: 'Intro to Sociology', school_year: '2025 - 26', students: '10' }]
        }

        expect(AdoptionReport.last.book).to eq(book)
      end

      it 'leaves book nil when no catalog Book matches the title' do
        post :create, params: {
          books: [{ name: 'Some Unknown Title', school_year: '2025 - 26', students: '10' }]
        }

        expect(AdoptionReport.last.book).to be_nil
      end

      it 'upserts instead of duplicating when the same book/year is submitted again' do
        post :create, params: {
          books: [{ name: 'Intro to Sociology', school_year: '2025 - 26', students: '10' }]
        }

        expect {
          post :create, params: {
            books: [{ name: 'Intro to Sociology', school_year: '2025 - 26', students: '25' }]
          }
        }.not_to change { AdoptionReport.count }

        expect(AdoptionReport.last.students).to eq(25)
      end

      it 'skips fully blank rows' do
        expect {
          post :create, params: {
            books: [
              { name: '', school_year: '', students: '' },
              { name: 'Intro to Sociology', school_year: '2025 - 26', students: '10' }
            ]
          }
        }.to change { AdoptionReport.count }.by(1)
      end

      it 'rejects a submission with no valid rows and redirects with an error' do
        expect {
          post :create, params: {
            books: [{ name: '', school_year: '', students: '' }]
          }
        }.not_to change { AdoptionReport.count }

        expect(response).to redirect_to(account_books_path)
        expect(flash[:alert]).to be_present
      end

      it 'rejects a submission missing the books param entirely' do
        expect {
          post :create, params: {}
        }.not_to change { AdoptionReport.count }

        expect(response).to redirect_to(account_books_path)
        expect(flash[:alert]).to be_present
      end
    end
  end
end
