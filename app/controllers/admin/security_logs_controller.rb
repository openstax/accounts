module Admin
  class SecurityLogsController < Admin::BaseController
    layout 'admin'
    def show
      search_params = params[:search] ? params[:search].permit!.to_h : {}
      items = SearchSecurityLog.call(search_params).outputs.items || SecurityLog.none
      @security_log = items.paginate(page: params[:page], per_page: params[:per_page] || 20)
    end
  end
end
