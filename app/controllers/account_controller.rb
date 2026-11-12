require 'bigdecimal'

class AccountController < Newflow::BaseController
  before_action :newflow_authenticate_user!
  before_action :prevent_caching

  layout 'application'

  NAV_ITEMS = [
    { key: :overview,  label: 'Account overview',   path: :account_overview_path },
    { key: :profile,   label: 'Profile',            path: :account_profile_path },
    { key: :security,  label: 'Security',           path: :account_security_path },
    { key: :books,     label: 'My OpenStax Books',  path: :account_books_path },
    { key: :impact,    label: 'My OpenStax Impact', path: :account_impact_path },
    { key: :support,   label: 'Support',            path: :account_support_path }
  ].freeze

  def overview
    if current_user.student?
      render_student_overview
    elsif current_user.self_learner?
      render_learner_overview
    else
      # Shown once until answered/dismissed; the completeness meter's "+ Answer
      # LMS question" chip can force it back open with ?show_lms=1.
      @show_lms_card = !current_user.lms_answered? &&
                       (current_user.lms_question_pending? || params[:show_lms].present?)
      @show_profile_nudge_banner = show_profile_nudge_banner?
      check_in_term = current_user.check_in_term
      check_in = AnnualCheckIn.new(current_user, term: check_in_term) if check_in_term
      @annual_check_in = check_in if check_in&.rows&.any?
      @overview_impact = OverviewImpact.new(current_user)
      assign_term_books unless @annual_check_in
      assign_term_books unless @annual_check_in

      render_account_page :overview, title: 'Account overview'
    end
  end

  def profile
    current_year = SchoolYear.current
    adoptions = adoptions_for_current_user
    @current_year_has_confirmed_adoption = adoptions.any? do |adoption|
      (adoption.school_year.presence || adoption.school_year_label) == current_year
    end
    @last_adoption_reported_at = last_reported_at_for(adoptions)
    render_account_page :profile, title: 'Profile'
  end

  def security
    render_account_page :security, title: 'Security'
  end

  def books
    @book_catalog = BookCatalog.new
    @saved_books = current_user.user_books.includes(:book).order(created_at: :desc)

    # Book rows are kept in sync by the daily cron (BookCatalogSync) —
    # don't call Salesforce from the request path.
    @available_books = @book_catalog.available_books.presence || books_from_db

    saved_ids = @saved_books.map { |saved| saved.book&.book_uuid }.compact
    @available_books_for_select = @available_books.reject { |book| saved_ids.include?(book[:book_uuid].to_s) }

    @available_books_for_select = books_from_db(exclude_ids: saved_ids) if @available_books_for_select.blank?

    @reported_school_year = SchoolYear.current
    @reported_titles = current_user.titles_reported_for(@reported_school_year).to_set
    @book_status_by_title = current_user.adoption_reports.where(school_year: @reported_school_year,
                                                                status: %w[considering browsing not_using])
                                        .pluck(:book_title, :status).to_h

    @can_report_adoptions = !current_user.student? && !current_user.self_learner?
    # Edits only stick once they reach Salesforce; with the push off, the next sync would undo them.
    @show_book_interests = @can_report_adoptions && Settings::Salesforce.push_book_interest_enabled
    catalog = @can_report_adoptions ? AdoptionBookCatalog.books : []
    @report_abbreviation_by_title = catalog.to_h { |book| [book.title, book.salesforce_abbreviation] }
    assign_book_interests(catalog) if @can_report_adoptions

    render_account_page :books,
                        title: 'My OpenStax Books'
  end

  def impact
    return redirect_to(account_overview_path) if current_user.self_learner?

    requested_view = params[:view].presence || params[:scope]
    @view = requested_view.in?(%w[current lifetime]) ? requested_view : 'current'
    @current_school_year = SchoolYear.current

    base_relation = adoptions_for_current_user.includes(:book)
    current_year_relation = base_relation.where(school_year: @current_school_year)

    @current_year_adoptions = sort_adoptions(current_year_relation.to_a)
    @lifetime_adoptions = sort_adoptions(base_relation.to_a)
    @active_adoptions = @view == 'lifetime' ? @lifetime_adoptions : @current_year_adoptions

    @current_year_stats = metrics_for(@current_year_adoptions)
    @lifetime_stats = metrics_for(@lifetime_adoptions)
    @active_stats = @view == 'lifetime' ? @lifetime_stats : @current_year_stats

    @current_year_has_adoptions = @current_year_adoptions.any?
    @active_has_adoptions = @active_adoptions.any?
    @milestones = ImpactMilestones.for(@lifetime_adoptions)
    @current_year_last_reported_at = last_reported_at_for(@current_year_adoptions)
    @lifetime_last_reported_at = last_reported_at_for(@lifetime_adoptions)
    @badge_last_reported_at = @current_year_last_reported_at || @lifetime_last_reported_at

    # User-reported signals, distinct from the Salesforce-confirmed adoptions above —
    # shown separately since they're pending confirmation.
    @pending_impact = PendingImpact.new(current_user, school_year: @current_school_year)
    @self_reported_adoptions = @pending_impact.reports
    @check_in_streak_years = current_user.check_in_streak_years

    saved_titles = current_user.user_books.includes(:book).filter_map { |user_book| user_book.book&.title }.uniq
    answered_titles = current_user.titles_answered_for(@current_school_year)
    @saved_books_total = saved_titles.size
    @saved_books_answered = (saved_titles & answered_titles).size

    render_account_page :impact,
                        title: 'My OpenStax Impact'
  end

  def support
    render_account_page :support, title: 'Support'
  end

  private

  def show_profile_nudge_banner?
    return false unless current_user.needs_profile_nudge? && !session[:profile_nudge_dismissed]

    unless SecurityLog.exists?(user: current_user, event_type: :profile_nudge_banner_shown)
      security_log(:profile_nudge_banner_shown)
    end
    true
  end

  def render_student_overview
    @saved_books = current_user.user_books.includes(:book).order(created_at: :desc)
    @instructor_connections = current_user.instructor_connections.order(created_at: :desc)
    @term_options = TermOptions.upcoming

    render_account_page :overview,
                        title: 'Your OpenStax Account',
                        view: 'student_overview'
  end

  def render_learner_overview
    @saved_books = current_user.user_books.includes(:book).order(created_at: :desc)

    render_account_page :overview,
                        title: 'Your OpenStax Account',
                        view: 'learner_overview'
  end

  PAGE_TITLES = {
    overview: 'Account overview', profile: 'Profile', security: 'Security',
    books: 'Books', impact: 'Impact', support: 'Support'
  }.freeze

  def render_account_page(current_key, title:, view: current_key)
    @page_title = "#{PAGE_TITLES.fetch(current_key)} - My OpenStax"
    @account_nav_items = account_nav_items_for(current_user)
    @account_nav_current = current_key
    @account_shell_title = title
    @framed = false
    @using_os = current_user.using_openstax
    render "account/#{view}"
  end

  # Students see their saved books on the overview and have no adoption
  # impact to report — those tabs are instructor-only. The pages themselves
  # stay reachable by URL; this only trims the nav.
  STUDENT_HIDDEN_NAV_KEYS = %i[books impact].freeze
  # Learners keep their books tab but have no adoptions to report.
  LEARNER_HIDDEN_NAV_KEYS = %i[impact].freeze

  def account_nav_items_for(user)
    hidden = if user.student? then STUDENT_HIDDEN_NAV_KEYS
             elsif user.self_learner? then LEARNER_HIDDEN_NAV_KEYS
             else return NAV_ITEMS
             end

    NAV_ITEMS.reject { |item| hidden.include?(item[:key]) }
  end

  TERM_BOOKS_LIMIT = 4

  # The newest saved books with this school year's answer for each: a count, the book rows
  # and two answer queries, however many books are saved.
  def assign_term_books
    @term_school_year = SchoolYear.current
    saved = current_user.user_books.joins(:book).includes(:book).order(created_at: :desc)
    @term_books_total = saved.count
    reported = current_user.titles_reported_for(@term_school_year).to_set
    statuses = current_user.adoption_reports.where(school_year: @term_school_year)
                           .pluck(:book_title, :status).to_h
    @term_books = saved.limit(TERM_BOOKS_LIMIT).map do |saved_book|
      title = saved_book.book.title
      { book: saved_book.book, answer: reported.include?(title) ? 'reported' : statuses[title] }
    end
  end

  def assign_book_interests(catalog)
    titles = catalog.to_h { |book| [book.salesforce_abbreviation, book.title] }
    listed = BookInterest.parse(current_user.which_books)
    @interest_books = listed.map { |abbreviation| { abbreviation: abbreviation, title: titles[abbreviation] || abbreviation } }
                            .sort_by { |entry| entry[:title].downcase }
    @interest_addable = catalog.reject { |book| listed.include?(book.salesforce_abbreviation) }
  end

  def books_from_db(exclude_ids: [])
    scope = exclude_ids.present? ? Book.where.not(book_uuid: exclude_ids) : Book.all
    scope.order(:title).map do |book|
      {
        title: book.title,
        book_uuid: book.book_uuid,
        cover_url: book.cover_url,
        webview_rex_link: book.webview_rex_link,
        html_url: book.html_url,
        salesforce_name: book.salesforce_name,
        assignable_book: book.assignable_book
      }
    end
  end

  def adoptions_for_current_user
    Adoption.where(
      user_id: current_user.id,
      confirmation_type: 'OpenStax Confirmed Adoption',
      rollover_status: false
    )
  end

  def sort_adoptions(adoptions)
    adoptions.sort_by do |adoption|
      [
        -(adoption.base_year || adoption.school_year_start || -Float::INFINITY),
        adoption.book&.title.to_s.downcase
      ]
    end
  end

  def metrics_for(adoptions)
    students = adoptions.sum { |adoption| adoption.students.to_i }
    savings = adoptions.reduce(BigDecimal('0')) do |memo, adoption|
      adoption.savings.present? ? memo + adoption.savings : memo
    end

    {
      students: students,
      books: adoptions.map { |adoption| adoption.book&.id || adoption.salesforce_book_id }.compact.uniq.count,
      years: adoptions.map { |adoption| adoption.school_year.presence || adoption.school_year_label }.compact.uniq.count,
      savings: savings
    }
  end

  def last_reported_at_for(adoptions)
    timestamps = adoptions.filter_map do |adoption|
      adoption.confirmation_date ||
        adoption.updated_at ||
        adoption.created_at
    end

    timestamps.max
  end
end
