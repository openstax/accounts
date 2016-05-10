module Admin
  class SecurityLogsController < BaseController

    def show
      @security_log = SearchSecurityLog.call(params[:search] || {}).outputs.items
                                       .paginate(page: params[:page],
                                                 per_page: params[:per_page] || 20)
    end

  end
end
