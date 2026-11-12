require 'csv'

module Admin
  # Works through "using" adoption reports held back from Salesforce because the student count
  # is over Settings::Salesforce.adoption_review_student_threshold.
  class AdoptionReviewsController < Admin::BaseController
    layout 'admin'

    FILTERS = { 'needs_review' => 'Needs review', 'approved' => 'Approved', 'rejected' => 'Rejected' }.freeze
    DEFAULT_FILTER = 'needs_review'.freeze
    PER_PAGE = 50
    CSV_HEADERS = ['User', 'Email', 'School', 'Book', 'School year', 'Students', 'How using',
                   'Source', 'Surface', 'Review status', 'Reported at', 'Reviewed at', 'Reviewed by'].freeze

    before_action :load_report, only: [:approve, :approve_with_count, :reject]

    def index
      @filter = FILTERS.key?(params[:filter]) ? params[:filter] : DEFAULT_FILTER
      @counts = AdoptionReport.where(review_status: FILTERS.keys).group(:review_status).count
      reports = AdoptionReport.where(review_status: @filter)
                              .includes(:reviewed_by, user: [:school, :email_addresses])
                              .order(created_at: :desc, id: :desc)

      respond_to do |format|
        format.html { @reports = reports.paginate(page: params[:page], per_page: PER_PAGE) }
        format.csv do
          send_data csv_for(reports), type: 'text/csv', disposition: 'attachment',
                                      filename: "adoption-reviews-#{@filter.dasherize}-#{Time.zone.today}.csv"
        end
      end
    end

    def approve
      decide('approved', :adoption_report_approved, 'Approved. It will go to Salesforce with the next push.')
    end

    def approve_with_count
      students = Integer(params[:students].to_s, 10, exception: false)
      if students.nil? || students.negative?
        return redirect_back_to_list(alert: 'Enter a whole number of students, zero or more.')
      end

      decide('approved', :adoption_report_count_changed_and_approved,
             "Count changed to #{students} and approved.", students: students)
    end

    def reject
      decide('rejected', :adoption_report_rejected, 'Rejected. It stays in Accounts and is never sent to Salesforce.')
    end

    helper_method def school_name_for(user)
      user.school&.name.presence || user.self_reported_school.presence
    end

    private

    def load_report
      @report = AdoptionReport.find(params[:id])
    end

    def decide(status, event_type, notice, students: nil)
      previous_students = @report.students
      attrs = { review_status: status, reviewed_at: Time.current, reviewed_by: current_user }
      attrs[:students] = students if students

      if @report.update(attrs)
        event_data = { adoption_report_id: @report.id, user_id: @report.user_id, book: @report.book_title,
                       school_year: @report.school_year, students: @report.students }
        event_data[:previous_students] = previous_students if students
        security_log event_type, event_data
        PushAdoptionReports.perform_later(user: @report.user) if status == 'approved'
        redirect_back_to_list(notice: notice)
      else
        redirect_back_to_list(alert: @report.errors.full_messages.to_sentence)
      end
    end

    def redirect_back_to_list(flash_options)
      redirect_to admin_adoption_reviews_path(filter: params[:filter].presence), flash_options
    end

    def csv_for(reports)
      CSV.generate do |csv|
        csv << CSV_HEADERS
        reports.find_each do |report|
          user = report.user
          csv << [user.name, user.best_email_address_for_salesforce, school_name_for(user), report.book_title,
                  report.school_year, report.students, report.how_using, report.source, report.surface,
                  report.review_status, report.created_at.utc.iso8601, report.reviewed_at&.utc&.iso8601,
                  report.reviewed_by&.username].map { |cell| csv_safe(cell) }
        end
      end
    end

    # A cell starting with one of these is run as a formula by spreadsheets.
    def csv_safe(cell)
      cell.is_a?(String) && cell.match?(/\A[=+\-@\t\r]/) ? "'#{cell}" : cell
    end
  end
end
