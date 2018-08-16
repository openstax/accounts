module Admin
  class SecurityLogsController < BaseController
    layout 'admin'

    def show
      items = SearchSecurityLog.call(params[:search] || {}).outputs.items || SecurityLog.none
      @security_log = items.paginate(page: params[:page], per_page: params[:per_page] || 20)
    end
  end
end
