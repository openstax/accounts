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
      redirect_to admin_salesforce_path
    end

  end
end
