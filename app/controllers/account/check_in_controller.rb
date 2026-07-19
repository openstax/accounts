module Account
  # The annual instructor check-in interstitial. Deliberately does NOT
  # extend the gate it's built to satisfy -- this controller is the
  # destination the gate redirects to, so it must skip its own before_action
  # or a signed-in, due-for-check-in user could never reach it.
  class CheckInController < AccountController
    skip_before_action :redirect_to_check_in_if_due

    def show
      @school_name = current_user.school&.name
      @book_rows = check_in_book_rows
      @show_dismiss = !current_user.check_in_required?

      render_account_page :check_in, title: 'Annual check-in', description: nil
    end

    def confirm
      current_school_year = AdoptionReport.current_school_year_label
      students_by_user_book_id = params.fetch(:students, {}).to_unsafe_h

      ActiveRecord::Base.transaction do
        current_user.user_books.includes(:book).find_each do |user_book|
          book = user_book.book
          next if book.nil?

          report = current_user.adoption_reports.find_or_initialize_by(
            book_title: book.title,
            school_year: current_school_year
          )

          # Keys are prefixed ("book_<id>"), not bare numeric strings -- a bare
          # numeric key (e.g. "8") crashes JsonAndStringParameterFilter, which
          # tries `JSON.parse` on every nested param key before filtering logs.
          students = students_by_user_book_id[check_in_student_field_key(user_book.id)].presence

          report.book = book
          report.status = 'using'
          report.source = 'check_in'
          report.students = students if students.present?
          report.save!
        end

        current_user.update!(
          check_in_completed_at: Time.current,
          check_in_dismissed_at: nil,
          check_in_dismissal_count: 0
        )
      end

      flash[:notice] = t('annual_check_in.confirmed_flash')
      redirect_to_check_in_destination(default: account_overview_path)
    end

    def dismiss
      if current_user.effective_check_in_dismissal_count >= User::CHECK_IN_DISMISSAL_LIMIT
        redirect_to(account_check_in_path, alert: t('annual_check_in.dismiss_refused'))
        return
      end

      current_user.update!(
        check_in_dismissed_at: Time.current,
        check_in_dismissal_count: current_user.effective_check_in_dismissal_count + 1
      )

      redirect_to_check_in_destination(default: account_overview_path)
    end

    private

    def check_in_book_rows
      last_school_year = SchoolYear.label_for(SchoolYear.base_year_for(Time.zone.today) - 1)

      current_user.user_books.includes(:book).order(:created_at).filter_map do |user_book|
        book = user_book.book
        next if book.nil?

        last_year_report = current_user.adoption_reports.find_by(
          book_title: book.title,
          school_year: last_school_year
        )

        {
          user_book_id: user_book.id,
          field_key: check_in_student_field_key(user_book.id),
          title: book.title,
          last_year_students: last_year_report&.students
        }
      end
    end

    def check_in_student_field_key(user_book_id)
      "book_#{user_book_id}"
    end
  end
end
