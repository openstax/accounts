module Oauth
  class ApplicationsController < Doorkeeper::ApplicationsController
    skip_before_filter :authenticate_admin!
    before_filter :authenticate_user!

    def index
      @user = current_user
      @applications = @user.is_administrator? ? Applications.all :
                                                @user.oauth_applications
    end

    def create
      @application = Doorkeeper::Application.new(application_params)
      @application.owner = current_user
      if @application.save
        flash[:notice] = I18n.t(:notice, :scope => [:doorkeeper, :flash,
                                                    :applications, :create])
        respond_with [:oauth, @application]
      else
        render :new
      end
    end
    
    private
    
    def application_params
      if params.respond_to?(:permit)
        params.require(:application).permit(:name, :redirect_uri)
      else
        params[:application].slice(:name, :redirect_uri) rescue nil
      end
    end
  end
end