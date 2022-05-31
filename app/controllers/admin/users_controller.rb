module Admin
  class UsersController < BaseController
    before_action :get_user, only: [:edit, :update, :destroy, :become]

    def index; end
    def edit; end

    # Used by full console page
    def search
      security_log :users_searched_by_admin, search: params[:search]
      handle_with(UsersSearch, complete: lambda { render 'index' })
    end

    def update
      was_administrator = @user.is_administrator

      respond_to do |format|
        if change_user_password && add_email_to_user && change_salesforce_contact && update_user
          security_log :user_updated_by_admin, user_id: params[:id], username: @user.username,
                                               user_params: request.filtered_parameters['user']

          security_log :admin_created, user_id: params[:id], username: @user.username \
            if @user.is_administrator && !was_administrator
          security_log :admin_deleted, user_id: params[:id], username: @user.username \
            if !@user.is_administrator && was_administrator

          security_log :trusted_launch_removed, user_id: params[:id], username: @user.username \
            if params[:user][:keep_external_uuids] == '0'

          format.html { redirect_to edit_admin_user_path(@user),
                        notice: t('.success') }
        else
          format.html { render action: "edit" }
        end
      end
    end

    # TODO: should this be possible? If so.. we need to do more with it
    def destroy
      security_log :user_deleted_by_admin, user_id: params[:id], username: @user.username
      @user.destroy
      redirect_to users_url
    end

    def become
      admin = current_user
      security_log :admin_became_user, user_id: params[:id], username: @user.username
      sign_in!(@user)
      security_log :sign_in_successful, admin_user_id: admin.id, admin_username: admin.username
      redirect_to request.referrer
    end

    def mark_users_updated
      ApplicationUser.update_all('unread_updates = unread_updates + 1') # rubocop:disable Rails/SkipsModelValidations
      redirect_to actions_admin_users_path, notice: t('.incremented')
    end

    protected

    def get_user
      @user = User.find(params[:id])
    end

    def add_email_to_user
      result = CreateEmailForUser.call(params[:user][:email_address], @user)
      return true unless result.errors.any?
      flash[:alert] = "Failed to add new email address: #{result.errors.collect(&:translate)}"
    end

    def change_user_password
      return true if params[:user][:password].blank?

      @user.identity.password = params[:user][:password]
      @user.identity.password_confirmation = params[:user][:password]
      return true if @user.identity.save
      flash[:alert] = "Failed to change password: #{@user.identity.errors.full_messages}"
    end

    def change_salesforce_contact
      new_id = params[:user][:salesforce_contact_id]

      if new_id.blank? || new_id == @user.salesforce_contact_id
        return true
      end

      if new_id.downcase == "remove"
        flash[:notice] = t('.removed')
        @user.salesforce_contact_id = nil
        return @user.save
      end

      begin
        contact = OpenStax::Salesforce::Remote::Contact.find(new_id)

        if contact.present?
          # The contact really exists, so save its ID to the User
          flash[:notice] = t('.updated')
          @user.salesforce_contact_id = new_id
          return @user.save
        end
      rescue
        # exploded, probably due to badly formed SF ID
      end

      # if haven't returned yet, either exploded or contact was `nil` (not found)
      flash[:alert] = "Can't find a Salesforce contact with ID #{new_id}"
    end

    def update_user
      @user.is_administrator = params[:user][:is_administrator]
      @user.is_test = params[:user][:is_test]
      @user.opt_out_of_cookies = params[:user][:opt_out_of_cookies]
      @user.role = params[:user][:role] if params[:user][:role]
      @user.faculty_status = params[:user][:faculty_status] if params[:user][:faculty_status]
      @user.school_type = params[:user][:school_type] if params[:user][:school_type]
      @user.school_location = params[:user][:school_location] if params[:user][:school_location]
      @user.is_kip = params[:user][:is_kip]
      @user.grant_tutor_access = params[:user][:grant_tutor_access]
      if @user.external_uuids.any? && params[:user][:keep_external_uuids] == '0'
        @user.external_uuids.destroy_all
      end
      user_params = params.require(:user).permit(:first_name, :last_name, :username)

      @user.update(user_params)
    end
  end
end
