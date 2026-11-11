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
    # A book the CMS list doesn't know or a how_using outside Salesforce's
    # picklist is dropped, so it can never reach a payload Salesforce would fault on.
    def valid_rows(raw_rows)
      rows = raw_rows.respond_to?(:values) ? raw_rows.values : Array(raw_rows)
      catalog = AdoptionBookCatalog.new

      rows.filter_map do |row|
        next unless row.respond_to?(:[])

        abbreviation = row[:name].to_s.strip
        school_year = row[:school_year].to_s.strip
        how_using = row[:how_using].to_s.strip
        next if abbreviation.blank? || school_year.blank?

        title = catalog.title_for(abbreviation)
        next if title.nil? || !AdoptionReport::HOW_USING_OPTIONS.include?(how_using)

        { book_title: title, salesforce_book_name: abbreviation, school_year: school_year,
          how_using: how_using, students: row[:students] }
      end
    end

    # The report modal is shared across account pages. Return users to the
    # page where they opened it, while accepting only known local paths.
    def return_path
      requested_path = params[:return_to].to_s.split('?').first
      surface_by_path.key?(requested_path) ? params[:return_to] : account_books_path
    end

    def surface_by_path
      {
        account_overview_path => 'overview',
        account_books_path => 'books',
        account_impact_path => 'impact',
        account_check_in_path => 'check_in'
      }
    end

    def surface
      surface_by_path.fetch(params[:return_to].to_s.split('?').first, 'books')
    end

    def upsert_adoption_report(row)
      scope = current_user.adoption_reports.where(school_year: row[:school_year])
      # A check-in row saved before salesforce_book_name existed is adopted rather than duplicated.
      report = scope.find_by(salesforce_book_name: row[:salesforce_book_name]) ||
               scope.find_by(book_title: row[:book_title], salesforce_book_name: nil) ||
               scope.new

      report.book_title = row[:book_title]
      report.salesforce_book_name = row[:salesforce_book_name]
      report.how_using = row[:how_using]
      report.surface = surface
      report.status = 'using'
      report.source = 'books_modal'
      report.book = Book.find_by(title: row[:book_title])
      report.students = row[:students] if row[:students].present?
      report.save
    end
  end
end
