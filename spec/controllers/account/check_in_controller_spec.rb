require 'rails_helper'

RSpec.describe Account::CheckInController, type: :controller do
  render_views

  let(:user) do
    FactoryBot.create(
      :user, :terms_agreed,
      role: User::INSTRUCTOR_ROLE,
      first_name: 'Sam',
      created_at: 2.years.ago
    )
  end
  let(:book) { Book.create!(book_uuid: SecureRandom.uuid, title: 'Intro to Sociology') }
  let!(:user_book) { UserBook.create!(user: user, book: book) }

  before { controller.sign_in! user }

  describe '#show' do
    it 'renders the interstitial for a due user' do
      get :show

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Annual check-in')
      expect(response.body).to include('Sam')
      expect(response.body).to include('Intro to Sociology')
    end

    it 'shows the "remind me" option below the dismissal limit' do
      get :show
      expect(response.body).to include('Remind me next week')
    end

    it 'hides the "remind me" option once check-in is required (2 dismissals used)' do
      user.update!(check_in_dismissed_at: 10.days.ago, check_in_dismissal_count: 2)

      get :show

      expect(response.body).not_to include('Remind me next week')
    end

    it 'prefills the student count from last school year\'s AdoptionReport' do
      last_year = SchoolYear.label_for(SchoolYear.base_year_for(Time.zone.today) - 1)
      AdoptionReport.create!(
        user: user, book: book, book_title: book.title, school_year: last_year,
        source: 'check_in', students: 75
      )

      get :show

      expect(response.body).to include('75 last year')
    end

    describe 'streak banner' do
      def report_for!(school_year)
        AdoptionReport.create!(user: user, book_title: book.title, school_year: school_year, source: 'books_modal')
      end

      it 'is omitted with no prior years reported' do
        get :show

        expect(response.body).not_to include('account-check-in__streak')
      end

      it 'uses singular copy for exactly one prior year' do
        report_for!(SchoolYear.label_for(SchoolYear.base_year_for(Time.zone.today) - 1))

        get :show

        expect(response.body).to include('account-check-in__streak')
        expect(response.body).to include('One year reported.')
        expect(response.body).to include('Confirm below to make it two.')
      end

      it 'uses plural "in a row" copy for two or more prior years' do
        report_for!(SchoolYear.label_for(SchoolYear.base_year_for(Time.zone.today) - 1))
        report_for!(SchoolYear.label_for(SchoolYear.base_year_for(Time.zone.today) - 2))

        get :show

        expect(response.body).to include('Two years reported in a row.')
        expect(response.body).to include('Confirm below to make it three.')
      end

      it 'renders one done circle per streak year plus a dashed pending-year circle' do
        report_for!(SchoolYear.label_for(SchoolYear.base_year_for(Time.zone.today) - 1))
        report_for!(SchoolYear.label_for(SchoolYear.base_year_for(Time.zone.today) - 2))

        get :show

        expect(response.body.scan('account-check-in__streak-circle--done').size).to eq 2
        expect(response.body.scan('account-check-in__streak-circle--pending').size).to eq 1

        pending_label = SchoolYear.short_label_for(SchoolYear.base_year_for(Time.zone.today))
        expect(response.body).to include(ERB::Util.html_escape(pending_label))
      end
    end
  end

  describe '#confirm' do
    it 'creates an AdoptionReport per current book with the submitted student counts' do
      expect {
        post :confirm, params: { students: { "book_#{user_book.id}" => '42' } }
      }.to change { AdoptionReport.count }.by(1)

      report = AdoptionReport.last
      expect(report.book_title).to eq('Intro to Sociology')
      expect(report.book_id).to eq(book.id)
      expect(report.school_year).to eq(AdoptionReport.current_school_year_label)
      expect(report.source).to eq('check_in')
      expect(report.status).to eq('using')
      expect(report.students).to eq(42)
    end

    it 'marks the check-in complete and clears any dismissal state' do
      user.update!(check_in_dismissed_at: 10.days.ago, check_in_dismissal_count: 1)

      post :confirm, params: { students: { "book_#{user_book.id}" => '10' } }

      user.reload
      expect(user.check_in_completed_at).to be_present
      expect(user.check_in_dismissed_at).to be_nil
      expect(user.check_in_dismissal_count).to eq(0)
    end

    it 'does not double-count when the user has more than one book' do
      other_book = Book.create!(book_uuid: SecureRandom.uuid, title: 'Chemistry Basics')
      other_user_book = UserBook.create!(user: user, book: other_book)

      post :confirm, params: {
        students: { "book_#{user_book.id}" => '10', "book_#{other_user_book.id}" => '20' }
      }

      expect(AdoptionReport.find_by(book_title: 'Intro to Sociology').students).to eq(10)
      expect(AdoptionReport.find_by(book_title: 'Chemistry Basics').students).to eq(20)
    end

    it 'redirects to the account overview when no destination was stored' do
      post :confirm, params: { students: {} }
      expect(response).to redirect_to(account_overview_path)
    end
  end

  describe '#dismiss' do
    it 'stamps a dismissal and increments the count' do
      expect {
        post :dismiss
      }.to change { user.reload.check_in_dismissal_count }.from(0).to(1)

      expect(user.reload.check_in_dismissed_at).to be_present
      expect(response).to redirect_to(account_overview_path)
    end

    it 'refuses a third dismissal once already at the limit' do
      user.update!(check_in_dismissed_at: 10.days.ago, check_in_dismissal_count: 2)

      expect {
        post :dismiss
      }.not_to(change { user.reload.check_in_dismissal_count })

      expect(response).to redirect_to(account_check_in_path)
      expect(flash[:alert]).to be_present
    end

    it 'allows dismissing again once the count reset for a new school year' do
      prior_school_year_start = Time.zone.local(SchoolYear.base_year_for(Time.zone.today), 8, 1)
      user.update!(check_in_dismissed_at: prior_school_year_start - 30.days, check_in_dismissal_count: 2)

      expect {
        post :dismiss
      }.to change { user.reload.check_in_dismissal_count }.to(1)
    end
  end
end
