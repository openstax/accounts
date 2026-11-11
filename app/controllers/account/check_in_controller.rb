module Account
  # Handles the inline annual check-in card on the account overview. Nothing
  # here blocks navigation; the card renders only while the check-in is due.
  class CheckInController < AccountController
    def show
      redirect_to account_overview_path(anchor: 'annual-check-in')
    end

    def confirm
      check_in = AnnualCheckIn.new(current_user)
      answers = params.fetch(:rows, {}).to_unsafe_h
      saved = []

      ActiveRecord::Base.transaction do
        check_in.rows.each do |row|
          answer = answers[row.key]
          next unless answer.is_a?(Hash) && answer['title'] == row.title

          status = answer['status'].to_s
          next unless AdoptionReport::VALID_STATUSES.include?(status)

          saved << save_report(row, status, answer)
        end

        current_user.update!(check_in_completed_at: Time.current, check_in_dismissed_at: nil) if saved.any?
      end

      if saved.empty?
        redirect_to account_overview_path(anchor: 'annual-check-in'), alert: t('annual_check_in.nothing_answered')
        return
      end

      using = saved.select { |report| report.status == 'using' }
      PushAdoptionReports.perform_later(user: current_user) if using.any?

      redirect_to account_overview_path, notice: confirmed_notice(using)
    end

    def dismiss
      current_user.update!(check_in_dismissed_at: Time.current)

      redirect_to account_overview_path, notice: t('annual_check_in.dismissed_flash')
    end

    private

    # Integers and fixed strings only: flashes render html_safe.
    def confirmed_notice(using)
      return t('annual_check_in.confirmed_flash') if using.empty?

      books = t('annual_check_in.flash_books', count: using.size)
      students = using.sum { |report| report.students.to_i }
      school_year = SchoolYear.current

      if students.positive?
        t('annual_check_in.confirmed_using_flash', books: books, school_year: school_year,
                                                   students: t('annual_check_in.flash_students', count: students))
      else
        t('annual_check_in.confirmed_using_books_only_flash', books: books, school_year: school_year)
      end
    end

    # Anything that isn't a whole number >= 0 is ignored rather than failing
    # save! (and the whole check-in) on a hand-crafted POST.
    def student_count(raw)
      count = Integer(raw.to_s.strip, 10, exception: false)
      count if count && count >= 0
    end

    # Returns the saved report. An existing row keeps its source: a row made in
    # the report modal must stay pushable, and a check-in must not relabel it.
    def save_report(row, status, answer)
      scope = current_user.adoption_reports.where(school_year: SchoolYear.current)
      report = (scope.find_by(salesforce_book_name: row.abbreviation) if row.abbreviation) ||
               scope.find_by(book_title: row.title) ||
               scope.new(source: 'check_in', surface: 'check_in')

      report.book_title = row.title
      report.book ||= Book.find_by(title: row.title)
      report.salesforce_book_name ||= row.abbreviation
      report.status = status

      if status == 'using'
        students = student_count(answer['students'])
        report.students = students unless students.nil?
        how_using = answer['how_using'].to_s
        if AdoptionReport::HOW_USING_OPTIONS.include?(how_using)
          report.how_using = how_using
        elsif report.how_using.blank?
          # A "using" row without a use would never be pushed (how_using is a
          # restricted picklist in Salesforce), so it defaults to primary textbook.
          report.how_using = AdoptionReport::HOW_USING_OPTIONS.first
        end
      end

      # Salesforce updates the adoption for the same book and year, so a changed count or use is safe to resend.
      if report.salesforce_pushed_at && (report.students_changed? || report.how_using_changed?)
        report.salesforce_pushed_at = nil
      end

      report.save!
      report
    end
  end
end
