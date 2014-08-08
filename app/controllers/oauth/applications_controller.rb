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
      @application.owner = Group.new
      @application.owner.add_member(current_user)
      @application.owner.add_owner(current_user)
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
    
    def user_params
      return {} if params[:application].nil?
      params[:application].slice(:name, :redirect_uri, :email_subject_prefix)
    end

    def admin_params
      return {} if params[:application].nil?
      params[:application].slice(:trusted, :email_from_address)
    end

    # We control which attributes of Doorkeeper::Applications can be updated
    # here, since they differ for normal users and administrators
    def application_params(user)
      user.is_administrator? ? \
        user_params.merge(admin_params) : user_params
    end
  end
end
