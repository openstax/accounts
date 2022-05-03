module Oauth
  class ApplicationsController < Doorkeeper::ApplicationsController
    include AuthenticateMethods

    layout 'admin'

    before_action :set_user
    before_action :authenticate_admin_or_oauth_application_owner!

    SPACE_SEPARATED_NUMBERS_REGEX = '^(?=.*\d)[\s\d]+$'.freeze

    def index
      @applications = @user.is_administrator? ? Doorkeeper::Application.all :
                                                @user.oauth_applications
      @applications = @applications.ordered_by(:created_at)

      respond_to do |format|
        format.html
        format.json { head :no_content }
      end
    end

    def show
      OSU::AccessPolicy.require_action_allowed!(:read, @user, @application)

      respond_to do |format|
        format.html
        format.json { render json: @application }
      end
    end

    def new
      @application = Doorkeeper::Application.new
      OSU::AccessPolicy.require_action_allowed!(:create, @user, @application)
    end

    def create
      @application = Doorkeeper::Application.new(app_params)
      @application.owner = Group.new
      @application.owner.add_member(current_user)
      @application.owner.add_owner(current_user)

      OSU::AccessPolicy.require_action_allowed!(:create, @user, @application)

      Doorkeeper::Application.transaction do
        if add_application_owners && @application.save
          security_log :application_created, application_id: @application.id,
                                            application_name: @application.name
          flash[:notice] = I18n.t(
            :notice, scope: %i[doorkeeper flash applications create]
          )
          respond_to do |format|
            format.html { redirect_to oauth_application_url(@application) }
            format.json { render json: @application }
          end
        else
          respond_to do |format|
            format.html { render :new }
            format.json do
              render json: { errors: @application.errors.full_messages },
                    status: :unprocessable_entity
            end
          end
          raise ActiveRecord::Rollback
        end
      end
    end

    def edit
      OSU::AccessPolicy.require_action_allowed!(:update, @user, @application)
      set_current_member_ids
    end

    def update
      OSU::AccessPolicy.require_action_allowed!(:update, @user, @application)

      Doorkeeper::Application.transaction do
        if add_application_owners && @application.update(app_params)
          security_log :application_updated, application_id: @application.id,
                                            application_params: app_params
          flash[:notice] = I18n.t(
            :notice, scope: %i[doorkeeper flash applications update]
          )
          respond_to do |format|
            format.html { redirect_to oauth_application_url(@application) }
            format.json { render json: @application }
          end
        else
          set_current_member_ids
          respond_to do |format|
            format.html { render :edit }
            format.json do
              render json: { errors: @application.errors.full_messages },
                    status: :unprocessable_entity
            end
          end
          raise ActiveRecord::Rollback
        end
      end
    end

    def destroy
      OSU::AccessPolicy.require_action_allowed!(:destroy, @user, @application)

      if @application.destroy
        flash[:notice] = I18n.t(
          :notice, scope: %i[doorkeeper flash applications destroy]
        )
        security_log :application_deleted, application_id: @application.id,
                                           application_name: @application.name
      end

      respond_to do |format|
        format.html { redirect_to oauth_applications_url }
        format.json { head :no_content }
      end
    end

    private

    def set_user
      @user = current_user
    end

    def app_params
      if @user.is_administrator?
        params.require(:doorkeeper_application).permit(
          :name, :redirect_uri, :scopes, :email_subject_prefix, :lead_application_source,
          :email_from_address, :confidential,
          :can_access_private_user_data, :can_find_or_create_accounts, :can_message_users,
          :can_skip_oauth_screen
        )
      elsif @user.oauth_applications.include?(@application)
        params.require(:doorkeeper_application).permit(
          :redirect_uri
        )
      end
    end

    def add_application_owners
      member_ids = validated_member_ids
      return false if @application.errors.any?
      return true if !current_user.is_administrator? &&
                     current_user.oauth_applications.include?(@application)

      @application.owner.update(member_ids: member_ids)
    end

    def validated_member_ids
      return [] if params[:member_ids].blank?

      unless params[:member_ids].match(SPACE_SEPARATED_NUMBERS_REGEX)
        @application.errors.add(:owner, 'Member Ids must be a space separated list of integers')
        return false
      end

      member_ids = params[:member_ids].split.map(&:to_i)
      member_ids.each do |member_id|
        unless User.exists?(id: member_id)
          @application.errors.add(:owner, "#{member_id} is not a valid user id")
          return false
        end
      end
      member_ids
    end

    def set_current_member_ids
      @member_ids = @application.owner.member_ids
    end

    def authenticate_admin_or_oauth_application_owner!
      return if current_user.oauth_applications.any?
      admin_authentication!
    end
  end
end
