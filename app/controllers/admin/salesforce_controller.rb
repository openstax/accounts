module Admin
  class SalesforceController < BaseController
    layout 'admin'

    def show
    end

    def callback
      user = SalesforceUser.save_from_omniauth!(env["omniauth.auth"])
      SalesforceUser.all.reject{|uu| uu.id == user.id}.each(&:destroy)
      redirect_to admin_salesforce_path
    end

    def destroy_user
      SalesforceUser.destroy_all
      ActiveForce.clear_sfdc_client! # since user is now gone, any client invalid
      redirect_to admin_salesforce_path
    end

    def update_users
      UpdateUserSalesforceInfo.call
      flash[:notice] = "The update completed."
      redirect_to admin_salesforce_path
    end

  end
end
