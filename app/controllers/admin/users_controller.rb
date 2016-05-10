module Admin
  class UsersController < BaseController

    before_filter :get_user, only: [:edit, :update, :destroy, :become, :make_admin]

    def index
      security_log :users_searched_by_admin, search: params[:search]
      handle_with(UsersSearch, complete: lambda { render 'search' })
    end

    def update
      security_log :user_updated_by_admin, user_id: params[:id],
                                           user_params: request.filtered_parameters['user']

      respond_to do |format|
        if change_user_password && add_email_to_user && update_user
          format.html { redirect_to edit_admin_user_path(@user),
                        notice: 'User profile was successfully updated.' }
        else
          format.html { render action: "edit" }
        end
      end
    end

    def destroy
      security_log :user_deleted_by_admin, user_id: params[:id]
      @user.destroy
      redirect_to users_url
    end

    def become
      security_log :admin_became_user, user_id: params[:id]
      sign_in!(@user)
      redirect_to request.referrer
    end

    def make_admin
      if @user.update_attribute(:is_administrator, true)
        security_log :admin_created, user_id: params[:id]
        redirect_to request.referrer, notice: 'User successfully updated.'
      else
        redirect_to request.referrer, alert: 'Unable to update user.'
      end
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
      return true if params[:user][:password].blank? && params[:user][:password_confirmation].blank?

      @user.identity.password = params[:user][:password]
      @user.identity.password_confirmation = params[:user][:password_confirmation]
      return true if @user.identity.save
      flash[:alert] = "Failed to change password: #{@user.identity.errors.full_messages}"
      return false
    end

    def update_user
      @user.is_administrator = params[:user][:is_administrator]

      user_params = params[:user].slice(:first_name, :last_name)
      @user.update_attributes(user_params)
    end
  end
end
