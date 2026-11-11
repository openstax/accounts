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
        redirect_to return_path, notice: thanks_message(rows)
      else
        # Static text only — flash notices/alerts are rendered html_safe by
        # the layout, so no user-typed row data belongs in here.
        redirect_to return_path,
                    alert: "Thanks for the report — some rows couldn't be saved. Please check your entries and try again."
      end
    end

    LOCAL_STATUSES = %w[considering browsing].freeze

    # "Considering it" and "Just looking" from a saved book's card. These are local answers: they
    # never reach Salesforce, and an existing "using" report is never downgraded from here.
    def book_status
      answer = params[:status].to_s
      book = current_user.user_books.includes(:book).find_by(id: params[:id])&.book

      if book.nil? || !LOCAL_STATUSES.include?(answer) || current_user.student? || current_user.self_learner?
        redirect_to account_books_path, alert: t('book_status.failed')
        return
      end

      abbreviation = AdoptionBookCatalog.books.find { |entry| entry.title == book.title }&.salesforce_abbreviation
      report = find_report(SchoolYear.current, book.title, abbreviation) || current_user.adoption_reports.new
      return redirect_to(account_books_path, notice: t('book_status.saved', school_year: SchoolYear.current)) if report.persisted? && report.status == 'using'

      report.assign_attributes(book_title: book.title, salesforce_book_name: abbreviation, school_year: SchoolYear.current,
                               status: answer, source: 'books_status', surface: 'books', book: book)

      if report.save
        add_to_interests(abbreviation) if answer == 'considering' && abbreviation.present? &&
                                          Settings::Salesforce.push_book_interest_enabled
        redirect_to account_books_path, notice: t('book_status.saved', school_year: SchoolYear.current)
      else
        redirect_to account_books_path, alert: t('book_status.failed')
      end
    end

    private

    # The list shows the book right after the redirect; Salesforce catches up in the background.
    def add_to_interests(abbreviation)
      BookInterest.update_user!(current_user, add: [abbreviation])
      PushBookInterest.perform_later(user: current_user, add: [abbreviation])
    end

    def find_report(school_year, title, abbreviation)
      scope = current_user.adoption_reports.where(school_year: school_year)
      (scope.find_by(salesforce_book_name: abbreviation) if abbreviation) ||
        scope.find_by(book_title: title, salesforce_book_name: nil)
    end

    # Integers and fixed strings only: flashes render html_safe. Only this school
    # year's rows show up as pending on the Impact tab (see PendingImpact).
    def thanks_message(rows)
      current = rows.select { |row| row[:school_year] == SchoolYear.current }
      return 'Thank you. Your report is saved and will count in your totals once we confirm it.' if current.empty?

      books = helpers.pluralize(current.size, 'book')
      students = current.sum { |row| row[:students].to_i }
      added = students.positive? ? "#{books} and #{helpers.pluralize(students, 'student')}" : books

      "Thank you. You added #{added} to your impact. This shows now as pending, and joins your totals once we confirm it."
    end

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
      # A check-in row saved before salesforce_book_name existed is adopted rather than duplicated.
      # An earlier considering or just looking answer is turned into this using report.
      report = find_report(row[:school_year], row[:book_title], row[:salesforce_book_name]) ||
               current_user.adoption_reports.new(school_year: row[:school_year])

      report.book_title = row[:book_title]
      report.salesforce_book_name = row[:salesforce_book_name]
      report.how_using = row[:how_using]
      report.surface = surface
      report.status = 'using'
      report.source = 'books_modal'
      report.book = Book.find_by(title: row[:book_title])
      report.students = row[:students] if row[:students].present?
      # Salesforce updates the existing adoption for the same book and year, so a
      # changed count or use is safe to send again.
      if report.salesforce_pushed_at && (report.students_changed? || report.how_using_changed?)
        report.salesforce_pushed_at = nil
      end
      report.save
    end
  end
end
