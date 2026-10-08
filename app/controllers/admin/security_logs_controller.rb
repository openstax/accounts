module Admin
  class SecurityLogsController < Admin::BaseController
    layout 'admin'

    PER_PAGE_OPTIONS = [20, 50, 100].freeze
    DEFAULT_PER_PAGE = PER_PAGE_OPTIONS.first

    def show
      search_params = params[:search] ? params[:search].permit!.to_h : {}
      items = SearchSecurityLog.call(search_params).outputs.items || SecurityLog.none
      @per_page = clamped_per_page
      @security_log = items.paginate(page: params[:page], per_page: @per_page)
    end

    private

    def clamped_per_page
      requested = params[:per_page].to_i
      PER_PAGE_OPTIONS.include?(requested) ? requested : DEFAULT_PER_PAGE
    end
  end
end
