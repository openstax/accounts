require 'bigdecimal'

class AccountController < Newflow::BaseController
  before_action :newflow_authenticate_user!

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
    render_account_page :overview, title: 'Account overview', description: 'View a summary of your OpenStax account.'
  end

  def profile
    current_year = SchoolYear.current
    adoptions = adoptions_for_current_user
    @current_year_has_confirmed_adoption = adoptions.any? do |adoption|
      (adoption.school_year.presence || adoption.school_year_label) == current_year
    end
    @last_adoption_reported_at = last_reported_at_for(adoptions)
    render_account_page :profile, title: 'Profile', description: 'Manage your personal details and preferences.'
  end

  def security
    render_account_page :security, title: 'Security', description: 'Review sign-in methods and security settings.'
  end

  def books
    @book_catalog = BookCatalog.new
    @saved_books = current_user.user_books.includes(:book).order(created_at: :desc)

    @available_books = @book_catalog.available_books.presence || books_from_db
    BookCatalogSync.new(@available_books).call if @available_books.present?

    saved_ids = @saved_books.map { |saved| saved.book&.book_uuid }.compact
    @available_books_for_select = @available_books.reject { |book| saved_ids.include?(book[:book_uuid].to_s) }

    @available_books_for_select = books_from_db(exclude_ids: saved_ids) if @available_books_for_select.blank?

    render_account_page :books,
                        title: 'My OpenStax Books',
                        description: 'Bookmark OpenStax titles so they are always in reach.'
  end

  def impact
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
    @current_year_last_reported_at = last_reported_at_for(@current_year_adoptions)
    @lifetime_last_reported_at = last_reported_at_for(@lifetime_adoptions)
    @badge_last_reported_at = @current_year_last_reported_at || @lifetime_last_reported_at

    render_account_page :impact,
                        title: 'My OpenStax Impact',
                        description: 'Monitor how OpenStax supports your students.'
  end

  def support
    render_account_page :support, title: 'Support', description: 'Get help from the OpenStax team.'
  end

  private

  def render_account_page(current_key, title:, description:)
    @account_nav_items = NAV_ITEMS
    @account_nav_current = current_key
    @account_shell_title = title
    @account_shell_description = description
    @framed = false
    @using_os = current_user.using_openstax
    render "account/#{current_key}"
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
