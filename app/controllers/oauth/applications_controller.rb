module Oauth
  class ApplicationsController < Doorkeeper::ApplicationsController
    before_action :set_user
    #before_action :admin_authentication!

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

      if @application.save
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
      end
    end

    def edit
      OSU::AccessPolicy.require_action_allowed!(:update, @user, @application)
      @member_ids = @application.owner.member_ids
    end

    def update
      OSU::AccessPolicy.require_action_allowed!(:update, @user, @application)
      
      Doorkeeper::Application.transaction do
        if handle_member_ids(params["member_ids"]) && @application.update_attributes(app_params)
          puts "***HERE in if of update"
          @application.owner.save
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
          puts "***HERE in else of update"
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
          :can_skip_oauth_screen, :member_ids
        )
      elsif @application.owner.member_ids.include?(@user.id)
        params.require(:doorkeeper_application).permit(
          :redirect_uri
        )
      end
    end

    def handle_member_ids(member_ids)
      if @user.is_administrator?
        if valid_member_ids(member_ids)
          puts "--- In valid member ids if ----"
          mi_array = member_ids.split(" ")
          puts "--- array created ----" + mi_array.to_s
          @application.owner.member_ids = mi_array if @application.owner.member_ids != mi_array
          puts "***WOW Member Ids Updated!!!"
          return true
        else
          puts "***In else of handle member ids"
          @application.errors.add(:owner, 'Member Ids must be a space separated list of integers')
          return false
        end
      else
        return false
      end
    end

    def valid_member_ids(member_ids)
      re = '^(?=.*\d)[\s\d]+$'
      result = !!member_ids.match(re)
      puts "***Valid Member Ids result!! " + result.to_s
      return result
    end
  end
end
