module Admin
  class SecurityLogsController < BaseController

    def show
      @security_log = params[:search] ? SearchSecurityLog.call(params[:search]).outputs.items : []
    end

  end
end
