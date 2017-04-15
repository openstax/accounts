module Admin
  class UsersController < BaseController
    layout 'admin', except: :js_search

    before_filter :get_user, only: [:edit, :update, :destroy, :become]

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
      was_administrator = @user.is_administrator

      respond_to do |format|
        if change_user_password && add_email_to_user && change_salesforce_contact && update_user
          security_log :user_updated_by_admin, user_id: params[:id], username: @user.username,
                                               user_params: request.filtered_parameters['user']

          security_log :admin_created, user_id: params[:id], username: @user.username \
            if @user.is_administrator && !was_administrator
          security_log :admin_deleted, user_id: params[:id], username: @user.username \
            if !@user.is_administrator && was_administrator

          format.html { redirect_to edit_admin_user_path(@user),
                        notice: 'User profile was successfully updated.' }
        else
          format.html { render action: "edit" }
        end
      end
    end

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

    protected

    def get_user
      @user = User.find(params[:id])
    end

    def add_email_to_user
      result = AddEmailToUser.call(params[:user][:email_address], @user)
      return true unless result.errors.any?
      flash[:alert] = "Failed to add new email address: #{result.errors.collect(&:translate)}"
      return false
    end

    def change_user_password
      return true if params[:user][:password].blank?

      @user.identity.password = params[:user][:password]
      @user.identity.password_confirmation = params[:user][:password]
      return true if @user.identity.save
      flash[:alert] = "Failed to change password: #{@user.identity.errors.full_messages}"
      return false
    end

    def change_salesforce_contact
      new_id = params[:user][:salesforce_contact_id]

      return true if new_id.blank? || new_id == @user.salesforce_contact_id

      new_id = nil if new_id == "remove"

      check_really_exists = new_id.present?

      if check_really_exists && !OpenStax::Salesforce.ready_for_api_usage?
        flash[:alert] = "Can't connect to Salesforce to verify changed contact ID"
        return false
      end

      begin
        contact = OpenStax::Salesforce::Remote::Contact.find(new_id) if check_really_exists
        # if didn't explode, we found it, let cron job update other info
        @user.salesforce_contact_id = new_id
        return @user.save
      rescue
        flash[:alert] = "Can't find a Salesforce contact with ID #{new_id}"
        return false
      end
    end

    def update_user
      @user.is_administrator = params[:user][:is_administrator]
      @user.faculty_status = params[:user][:faculty_status] if params[:user][:faculty_status]

      user_params = params[:user].slice(:first_name, :last_name, :username)

      @user.update_attributes(user_params)
    end
  end
end
