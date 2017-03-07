module Admin
  class SalesforceController < BaseController
    layout 'admin'

    def show
    end

    def update_users
      UpdateUserSalesforceInfo.call(allow_error_email: true)
      flash[:notice] = "The update completed."
      redirect_to actions_admin_salesforce_path
    end

  end
end
