module Admin
  class SecurityLogsController < BaseController
    layout 'admin'

    def show
      items = SearchSecurityLog.call(search_params[:search] || {}).outputs.items || SecurityLog.none
      @security_log = items.paginate(page: search_params[:page], per_page: search_params[:per_page] || 20)
    end

  private

    def search_params
      params.permit!.to_h # safe because only admins can access this page
    end
  end
end
