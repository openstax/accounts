module Oauth
  class ApplicationsController < Doorkeeper::ApplicationsController
    before_filter :get_user
    before_filter :get_application, :only => [:show, :edit, :update, :destroy]

    def index
      @applications = @user.is_administrator? ? Doorkeeper::Application.all :
                                                @user.oauth_applications
    end

    def create
      @application = Doorkeeper::Application.new(application_params(@user))
      @application.owner = @user
      OSU::AccessPolicy.require_action_allowed!(:create, @user, @application)
      if @application.save
        flash[:notice] = I18n.t(:notice, :scope => [:doorkeeper, :flash,
                                                    :applications, :create])
        respond_with [:oauth, @application]
      else
        render :new
      end
    end

    def show
      OSU::AccessPolicy.require_action_allowed!(:read, @user, @application)
      super
    end

    def edit
      OSU::AccessPolicy.require_action_allowed!(:update, @user, @application)
      super
    end

    def update
      OSU::AccessPolicy.require_action_allowed!(:update, @user, @application)
      if @application.update_attributes(application_params(@user))
        flash[:notice] = I18n.t(:notice, :scope => [:doorkeeper, :flash,
                                                    :applications, :update])
        respond_with [:oauth, @application]
      else
        render :edit
      end
    end

    def destroy
      OSU::AccessPolicy.require_action_allowed!(:destroy, @user, @application)
      super
    end

    protected

    def get_user
      @user = current_user
    end
    
    def get_application
      @application = Doorkeeper::Application.find(params[:id])
    end

    private

    def application_params(user)
      user.is_administrator? ? \
        user_params.merge(admin_params) : user_params
    end
    
    def user_params
      if params.respond_to?(:permit)
        params.require(:application).permit(:name, :redirect_uri)
      else
        params[:application].slice(:name, :redirect_uri) rescue nil
      end
    end

    def admin_params
      if params.respond_to?(:permit)
        params.require(:application).permit(:trusted,
          :email_from_address, :email_subject_prefix)
      else
        params[:application].slice(:trusted,
          :email_from_address, :email_subject_prefix) rescue nil
      end
    end
  end
end