require 'rails_helper'

describe Admin::AdoptionReviewsController, type: :controller do
  include ActiveJob::TestHelper

  let(:admin) { FactoryBot.create :user, :admin, :terms_agreed }
  let(:instructor) do
    FactoryBot.create :user, :terms_agreed, role: 'instructor', first_name: 'Ida', last_name: 'Teacher', school: nil,
                                            self_reported_school: 'Lakeside College'
  end

  def push_jobs
    enqueued_jobs.select { |job| job['arguments'].first == 'PushAdoptionReports' || job[:args]&.first&.first == 'PushAdoptionReports' }
  end

  def create_report(overrides = {})
    AdoptionReport.create!({
      user: instructor, book_title: 'Biology 2e', salesforce_book_name: 'Biology', school_year: '2026 - 27',
      status: 'using', source: 'books_modal', surface: 'books', students: 5000,
      how_using: AdoptionReport::HOW_USING_OPTIONS.first
    }.merge(overrides))
  end

  context 'as a non-admin' do
    before { controller.sign_in! FactoryBot.create(:user, :terms_agreed) }

    it 'refuses every action' do
      report = create_report

      get :index
      expect(response).to have_http_status(:forbidden)
      post :approve, params: { id: report.id }
      expect(response).to have_http_status(:forbidden)
      post :approve_with_count, params: { id: report.id, students: 10 }
      expect(response).to have_http_status(:forbidden)
      post :reject, params: { id: report.id }
      expect(response).to have_http_status(:forbidden)

      expect(report.reload.review_status).to eq 'needs_review'
    end
  end

  context 'as an admin' do
    before { controller.sign_in! admin }

    describe 'GET #index' do
      let!(:held) { create_report }
      let!(:approved) { create_report(book_title: 'Physics', salesforce_book_name: 'Physics').tap { |r| r.update!(review_status: 'approved') } }
      let!(:rejected) { create_report(book_title: 'Chemistry', salesforce_book_name: 'Chemistry').tap { |r| r.update!(review_status: 'rejected') } }
      let!(:normal) { create_report(book_title: 'Calculus', salesforce_book_name: 'Calculus', students: 30) }

      it 'defaults to the needs-review tab' do
        get :index

        expect(response).to have_http_status(:ok)
        expect(assigns(:filter)).to eq 'needs_review'
        expect(assigns(:reports)).to contain_exactly(held)
        expect(assigns(:counts)).to eq('needs_review' => 1, 'approved' => 1, 'rejected' => 1)
      end

      it 'filters to approved and rejected' do
        get :index, params: { filter: 'approved' }
        expect(assigns(:reports)).to contain_exactly(approved)

        get :index, params: { filter: 'rejected' }
        expect(assigns(:reports)).to contain_exactly(rejected)
      end

      it 'falls back to needs review for an unknown filter' do
        get :index, params: { filter: 'everything' }
        expect(assigns(:reports)).to contain_exactly(held)
      end

      context 'with views' do
        render_views

        it 'shows the report details and the three actions' do
          get :index

          expect(response.body).to include('Ida Teacher', 'Lakeside College', 'Biology 2e', '2026 - 27', '5,000')
          expect(response.body).to include('Approve', 'Reject', 'Change count and approve')
          expect(response.body).to include(edit_admin_user_path(instructor))
        end
      end
    end

    describe 'GET #index as CSV' do
      it 'downloads the current filter' do
        create_report
        create_report(book_title: 'Physics', salesforce_book_name: 'Physics').update!(review_status: 'rejected')

        get :index, params: { filter: 'needs_review' }, format: :csv

        expect(response.media_type).to eq 'text/csv'
        expect(response.headers['Content-Disposition']).to include('adoption-reviews-needs-review')
        rows = CSV.parse(response.body, headers: true)
        expect(rows.size).to eq 1
        expect(rows.first.to_h).to include('Book' => 'Biology 2e', 'Students' => '5000', 'School' => 'Lakeside College',
                                           'Review status' => 'needs_review')
      end

      it 'neutralises cells a spreadsheet would run as a formula' do
        instructor.update!(self_reported_school: '=HYPERLINK("http://example.test")')
        create_report

        get :index, format: :csv

        expect(CSV.parse(response.body, headers: true).first['School']).to start_with("'=")
      end
    end

    describe 'POST #approve' do
      it 'approves, stamps the reviewer, logs it and enqueues a push for the user' do
        report = create_report

        expect { post :approve, params: { id: report.id } }.to change { push_jobs.size }.by(1)
        expect(push_jobs.last.to_json).to include("User/#{instructor.id}")

        report.reload
        expect(report.review_status).to eq 'approved'
        expect(report.reviewed_by).to eq admin
        expect(report.reviewed_at).to be_within(1.minute).of(Time.current)
        expect(report.students).to eq 5000
        expect(response).to redirect_to(admin_adoption_reviews_path)

        log = SecurityLog.where(event_type: SecurityLog.event_types[:adoption_report_approved]).first
        expect(log.event_data).to include('adoption_report_id' => report.id, 'user_id' => instructor.id)
      end
    end

    describe 'POST #approve_with_count' do
      it 'changes the count, approves, logs the old and new count and enqueues a push' do
        report = create_report

        expect { post :approve_with_count, params: { id: report.id, students: '800' } }.to change { push_jobs.size }.by(1)

        report.reload
        expect(report.students).to eq 800
        expect(report.review_status).to eq 'approved'
        expect(report.reviewed_by).to eq admin
        log = SecurityLog.where(event_type: SecurityLog.event_types[:adoption_report_count_changed_and_approved]).first
        expect(log.event_data).to include('students' => 800, 'previous_students' => 5000)
      end

      it 'refuses a count that is not a whole number zero or more' do
        report = create_report

        ['', 'lots', '-5', '12.5'].each do |bad|
          post :approve_with_count, params: { id: report.id, students: bad }
          expect(flash[:alert]).to be_present
        end

        expect(report.reload.students).to eq 5000
        expect(report.review_status).to eq 'needs_review'
      end
    end

    describe 'POST #reject' do
      it 'rejects, logs it and never enqueues a push' do
        report = create_report

        expect { post :reject, params: { id: report.id } }.not_to change { push_jobs.size }

        report.reload
        expect(report.review_status).to eq 'rejected'
        expect(report.reviewed_by).to eq admin
        expect(AdoptionReport.pushable).not_to include(report)
        expect(SecurityLog.where(event_type: SecurityLog.event_types[:adoption_report_rejected]).count).to eq 1
      end

      it 'keeps the filter the admin was on' do
        report = create_report

        post :reject, params: { id: report.id, filter: 'approved' }

        expect(response).to redirect_to(admin_adoption_reviews_path(filter: 'approved'))
      end
    end
  end
end
