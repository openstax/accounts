module Admin
  class UsersController < Admin::BaseController
    layout 'admin', except: :js_search

    before_action :get_user, only: [:edit, :update, :become, :soft_delete]

    # Used by dialog
    def js_search
      security_log :users_searched_by_admin, search: params[:search]
      handle_with(UsersSearch, complete: lambda { render 'search' })
    end

    def index; end

    # Used by full console page
    def search
      security_log :users_searched_by_admin, search: params[:search]
      handle_with(UsersSearch, complete: lambda { render 'index' })
    end

    def update
      User.transaction do
        was_administrator = @user.is_administrator
        old_updated_at = @user.updated_at

        respond_to do |format|
          if change_user_password && add_email_to_user && change_salesforce_contact && update_user
            @user.touch if @user.updated_at == old_updated_at
            security_log :user_updated_by_admin, user_id: params[:id], username: @user.username,
                                                user_params: request.filtered_parameters['user']

            security_log :admin_created, user_id: params[:id], username: @user.username \
              if @user.is_administrator && !was_administrator
            security_log :admin_deleted, user_id: params[:id], username: @user.username \
              if !@user.is_administrator && was_administrator

            security_log :trusted_launch_removed, user_id: params[:id], username: @user.username \
              if params[:user][:keep_external_uuids] == '0'

            format.html { redirect_to edit_admin_user_path(@user),
                          notice: 'User profile was successfully updated.' }
          else
            format.html { render action: "edit" }
          end
        end
      end
    end

    def soft_delete
      result = SoftDeleteUser.call(@user)

      security_log :user_deleted_by_admin, user: @user, admin_id: @current_user.id

      # redirect_to admin_users_path
      flash[:alert] = "Authentications and PII removed from account."
      redirect_to admin_users_path
    end

    def become
      admin = current_user
      security_log :admin_became_user, user_id: params[:id], username: @user.username
      sign_in!(@user)
      security_log :sign_in_successful, admin_user_id: admin.id, admin_username: admin.username
      redirect_to request.referrer
    end

    def mark_users_updated
      ApplicationUser.update_all('unread_updates = unread_updates + 1')
      redirect_to actions_admin_users_path, notice: 'Incremented unread update count'
    end

    def force_update_lead
      Newflow::CreateOrUpdateSalesforceLead.call(user: get_user)
    end

    protected

    def get_user
      @user = User.find(params[:id])
    end

    def add_email_to_user
      result = AddEmailToUser.call(params[:user][:email_address], @user)
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

      if new_id.downcase == 'remove'
        flash[:notice] = 'Removed the Salesforce Contact ID'
        @user.salesforce_contact_id = nil
        return @user.save
      end

      begin
        contact = OpenStax::Salesforce::Remote::Contact.find(new_id)

        if contact.present?
          # The contact really exists, so save its ID to the User
          flash[:notice] = 'Updated Salesforce Contact'
          @user.salesforce_contact_id = new_id
          return @user.save
        else
          flash[:alert] = "Can't find a Salesforce contact with ID #{new_id}"
        end
      rescue
        # exploded, probably due to badly formed SF ID
        flash[:alert] = 'Failed to update Salesforce Contact ID'
      end

      # if haven't returned yet, either exploded or contact was `nil` (not found)
      false
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

      @user.application_users = (params[:application_users]&.permit!&.to_h || {}).map do |_, au|
        application_user = @user.application_users.to_a.find do |a_user|
          a_user.application_id == au[:application_id].to_i
        end
        application_user = @user.application_users.new(application_id: au[:application_id].to_i)\
          if application_user.nil?
        application_user.roles = au[:roles].split(',').map(&:strip)
        application_user.save!
        application_user
      end
      @user.update! user_params
    end
  end
end
