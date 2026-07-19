module Account
  class AdoptionReportsController < Newflow::BaseController
    before_action :newflow_authenticate_user!

    def create
      rows = valid_rows(params[:books])

      if rows.blank?
        redirect_to account_books_path,
                    alert: 'Please select at least one book and school year to report an adoption.'
        return
      end

      rows.each { |row| upsert_adoption_report(row) }

      redirect_to account_books_path,
                  notice: "Thanks — your report helps us measure OpenStax's impact."
    end

    private

    # Skip fully blank rows (the modal always submits at least one row, plus
    # any the user added); a row only counts once it has a book and year.
    def valid_rows(raw_rows)
      Array(raw_rows).filter_map do |row|
        next unless row.respond_to?(:[])

        book_title = row[:name].to_s.strip
        school_year = row[:school_year].to_s.strip
        next if book_title.blank? || school_year.blank?

        { book_title: book_title, school_year: school_year, students: row[:students] }
      end
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
