module Account
  class AdoptionReportsController < Newflow::BaseController
    before_action :newflow_authenticate_user!

    def create
      rows = valid_rows(params[:books])

      if rows.blank?
        redirect_to return_path,
                    alert: 'Please select at least one book and school year to report an adoption.'
        return
      end

      results = rows.map { |row| upsert_adoption_report(row) }

      # Push happens in the background so a slow or failing Salesforce call
      # never delays or breaks the user's save/redirect.
      PushAdoptionReports.perform_later(user: current_user) if results.any?

      if results.all?
        redirect_to return_path,
                    notice: "Thanks — your report helps us measure OpenStax's impact."
      else
        # Static text only — flash notices/alerts are rendered html_safe by
        # the layout, so no user-typed row data belongs in here.
        redirect_to return_path,
                    alert: "Thanks for the report — some rows couldn't be saved. Please check your entries and try again."
      end
    end

    private

    # Skip fully blank rows (the modal always submits at least one row, plus
    # any the user added); a row only counts once it has a book and year.
    def valid_rows(raw_rows)
      rows = raw_rows.respond_to?(:values) ? raw_rows.values : Array(raw_rows)

      rows.filter_map do |row|
        next unless row.respond_to?(:[])

        book_title = row[:name].to_s.strip
        school_year = row[:school_year].to_s.strip
        next if book_title.blank? || school_year.blank?

        { book_title: book_title, school_year: school_year, students: row[:students] }
      end
    end

    # The report modal is shared across account pages. Return users to the
    # page where they opened it, while accepting only known local paths.
    def return_path
      allowed_paths = [account_overview_path, account_books_path, account_impact_path]
      requested_path = params[:return_to].to_s.split('?').first
      allowed_paths.include?(requested_path) ? params[:return_to] : account_books_path
    end

    def upsert_adoption_report(row)
      report = current_user.adoption_reports.find_or_initialize_by(
        book_title: row[:book_title],
        school_year: row[:school_year]
      )

      report.status = 'using'
      report.source = 'books_modal'
      report.book = Book.find_by(title: row[:book_title])
      report.students = row[:students] if row[:students].present?
      report.save
    end
  end
end
