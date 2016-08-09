module Oauth
  class ApplicationsController < Doorkeeper::ApplicationsController
    before_filter :get_user
    before_filter :get_application, :only => [:show, :edit, :update, :destroy]
    respond_to :html

    def index
      @applications = @user.is_administrator? ? Doorkeeper::Application.all :
                                                @user.oauth_applications
    end

    def new
      super
      OSU::AccessPolicy.require_action_allowed!(:create, @user, @application)
    end

    def create
      @application = Doorkeeper::Application.new(application_params(@user))
      @application.owner = Group.new
      @application.owner.add_member(current_user)
      @application.owner.add_owner(current_user)
      OSU::AccessPolicy.require_action_allowed!(:create, @user, @application)
      if @application.save
        security_log :application_created, application_id: @application.id,
                                           application_name: @application.name
        flash[:notice] = I18n.t(:notice, :scope => [:doorkeeper, :flash,
                                                    :applications, :create])
        render :show
      else
        render :new, status: :unprocessable_entity
      end
    end

    def show
      OSU::AccessPolicy.require_action_allowed!(:read, @user, @application)
    end

    def edit
      OSU::AccessPolicy.require_action_allowed!(:update, @user, @application)
    end

    def update
      OSU::AccessPolicy.require_action_allowed!(:update, @user, @application)
      app_params = application_params(@user)
      if @application.update_attributes(app_params)
        security_log :application_updated, application_id: @application.id,
                                           application_params: app_params
        flash[:notice] = I18n.t(:notice, :scope => [:doorkeeper, :flash,
                                                    :applications, :update])
        redirect_to action: :index
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      OSU::AccessPolicy.require_action_allowed!(:destroy, @user, @application)
      security_log :application_deleted, application_id: @application.id,
                                         application_name: @application.name
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
