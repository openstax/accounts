require 'rails_helper'

RSpec.describe Account::CheckInController, type: :controller do
  let(:user) do
    FactoryBot.create(:user, :terms_agreed, role: User::INSTRUCTOR_ROLE, created_at: 2.years.ago)
  end
  let(:how_using) { AdoptionReport::HOW_USING_OPTIONS.second }
  let(:current_year) { SchoolYear.current }
  let(:last_year) { SchoolYear.label_for(SchoolYear.base_year_for(Time.zone.today) - 1) }
  let!(:sociology) { Book.create!(book_uuid: SecureRandom.uuid, title: 'Introduction to Sociology 3e') }
  let!(:physics) { Book.create!(book_uuid: SecureRandom.uuid, title: 'College Physics') }

  before do
    allow_any_instance_of(FetchBookData).to receive(:books_by_subject).and_return([
      { subject_name: 'Social Sciences', books: [
        { title: 'Introduction to Sociology 3e', salesforce_abbreviation: 'Sociology', cover_url: nil }
      ] },
      { subject_name: 'Science', books: [
        { title: 'College Physics', salesforce_abbreviation: 'College Physics', cover_url: nil }
      ] }
    ])
    UserBook.create!(user: user, book: sociology)
    UserBook.create!(user: user, book: physics)
    controller.sign_in! user
  end

  def key_for(title)
    AnnualCheckIn.new(user).rows.find { |row| row.title == title }.key
  end

  def answer(title, **fields)
    { key_for(title) => { title: title }.merge(fields) }
  end

  describe '#show' do
    it 'redirects old links to the overview card instead of rendering a page' do
      get :show

      expect(response).to redirect_to(account_overview_path(anchor: 'annual-check-in'))
    end
  end

  describe '#confirm' do
    it 'saves using and not-using rows and enqueues the push' do
      rows = answer('Introduction to Sociology 3e', status: 'using', students: '42', how_using: how_using)
                .merge(answer('College Physics', status: 'not_using', students: '10'))

      expect(PushAdoptionReports).to receive(:perform_later).with(user: user)

      expect { post :confirm, params: { rows: rows } }.to change { AdoptionReport.count }.by(2)

      using = AdoptionReport.find_by!(book_title: 'Introduction to Sociology 3e')
      expect(using).to have_attributes(
        status: 'using', source: 'check_in', surface: 'check_in', students: 42, how_using: how_using,
        salesforce_book_name: 'Sociology', school_year: current_year, book_id: sociology.id
      )
      expect(AdoptionReport.find_by!(book_title: 'College Physics')).to have_attributes(
        status: 'not_using', source: 'check_in', how_using: nil, students: nil
      )
      expect(user.reload.check_in_completed_at).to be_present
      expect(response).to redirect_to(account_overview_path)
      expect(flash[:notice]).to eq(I18n.t('annual_check_in.confirmed_flash'))
    end

    it 'creates nothing for unanswered rows' do
      rows = answer('Introduction to Sociology 3e', status: 'using', how_using: how_using)
                .merge(answer('College Physics', students: '30', how_using: how_using))

      expect { post :confirm, params: { rows: rows } }.to change { AdoptionReport.count }.by(1)

      expect(AdoptionReport.pluck(:book_title)).to eq(['Introduction to Sociology 3e'])
    end

    it 'alerts and saves nothing when no row was answered' do
      expect { post :confirm, params: { rows: answer('College Physics', students: '5') } }
        .not_to(change { AdoptionReport.count })

      expect(response).to redirect_to(account_overview_path(anchor: 'annual-check-in'))
      expect(flash[:alert]).to eq(I18n.t('annual_check_in.nothing_answered'))
      expect(user.reload.check_in_completed_at).to be_nil
    end

    it 'ignores a row whose title does not match the card' do
      rows = { key_for('College Physics') => { title: 'Something else', status: 'using' } }

      expect { post :confirm, params: { rows: rows } }.not_to(change { AdoptionReport.count })
    end

    it 'enqueues the push only when a using row was saved' do
      expect(PushAdoptionReports).not_to receive(:perform_later)

      post :confirm, params: { rows: answer('College Physics', status: 'not_using') }
    end

    it 'enqueues the push for a using row' do
      expect(PushAdoptionReports).to receive(:perform_later).with(user: user)

      post :confirm, params: { rows: answer('College Physics', status: 'using', how_using: how_using) }
    end

    it 'ignores a student count that is not a whole number instead of failing' do
      %w[abc -3 4.5].each do |bad|
        post :confirm, params: { rows: answer('College Physics', status: 'using', students: bad, how_using: how_using) }

        expect(response).to redirect_to(account_overview_path)
        expect(AdoptionReport.find_by!(book_title: 'College Physics').students).to be_nil
      end
    end

    it 'ignores a how_using outside the Salesforce picklist' do
      post :confirm, params: { rows: answer('College Physics', status: 'using', how_using: 'Because') }

      expect(AdoptionReport.find_by!(book_title: 'College Physics').how_using).to be_nil
    end

    it 'keeps the source of an existing modal row and updates it in place' do
      modal = AdoptionReport.create!(
        user: user, book_title: 'College Physics', salesforce_book_name: 'College Physics',
        school_year: current_year, source: 'books_modal', surface: 'books', how_using: how_using
      )

      expect {
        post :confirm, params: { rows: answer('College Physics', status: 'using', students: '42', how_using: how_using) }
      }.not_to(change { AdoptionReport.count })

      expect(modal.reload).to have_attributes(source: 'books_modal', surface: 'books', students: 42)
    end

    it 'clears the pushed stamp when students or use changed on a pushed row' do
      pushed = AdoptionReport.create!(
        user: user, book_title: 'College Physics', salesforce_book_name: 'College Physics',
        school_year: current_year, source: 'books_modal', students: 10, how_using: how_using,
        salesforce_pushed_at: 1.day.ago
      )

      post :confirm, params: { rows: answer('College Physics', status: 'using', students: '55', how_using: how_using) }

      expect(pushed.reload.salesforce_pushed_at).to be_nil
    end

    it 'keeps the pushed stamp when nothing changed' do
      pushed = AdoptionReport.create!(
        user: user, book_title: 'College Physics', salesforce_book_name: 'College Physics',
        school_year: current_year, source: 'books_modal', students: 10, how_using: how_using,
        salesforce_pushed_at: 1.day.ago
      )

      post :confirm, params: { rows: answer('College Physics', status: 'using', students: '10', how_using: how_using) }

      expect(pushed.reload.salesforce_pushed_at).to be_present
    end

    it 'keeps a row local when the book is not in the Salesforce catalog' do
      other = Book.create!(book_uuid: SecureRandom.uuid, title: 'Obscure Book')
      UserBook.create!(user: user, book: other)

      post :confirm, params: { rows: answer('Obscure Book', status: 'using', how_using: how_using) }

      expect(AdoptionReport.find_by!(book_title: 'Obscure Book').salesforce_book_name).to be_nil
    end
  end

  describe '#dismiss' do
    it 'snoozes without limit' do
      3.times do
        post :dismiss
        expect(response).to redirect_to(account_overview_path)
      end

      expect(user.reload.check_in_dismissed_at).to be_present
      expect(user.annual_check_in_due?).to be false
    end
  end

  describe 'rows prefill' do
    it 'comes from last year\'s report, then confirmed adoption, deduped by title' do
      AdoptionReport.create!(
        user: user, book_title: 'College Physics', salesforce_book_name: 'College Physics',
        school_year: last_year, source: 'books_modal', students: 75, how_using: how_using
      )
      AdoptionReport.create!(
        user: user, book_title: 'Chemistry 2e', school_year: last_year, source: 'check_in', students: 20
      )

      rows = AnnualCheckIn.new(user).rows

      expect(rows.map(&:title)).to match_array(['Introduction to Sociology 3e', 'College Physics', 'Chemistry 2e'])
      expect(rows.find { |row| row.title == 'College Physics' }).to have_attributes(students: 75, how_using: how_using)
      expect(rows.find { |row| row.title == 'Chemistry 2e' }).to have_attributes(students: 20, how_using: nil)
    end
  end
end
