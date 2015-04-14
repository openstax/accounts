module Admin
  class UsersController < BaseController

    before_filter :get_user, only: [:show, :edit, :update, :destroy, :become, :make_admin]

    def index
      handle_with(UsersSearch,
                  complete: lambda { render 'search' })
    end

    def update
      respond_to do |format|
        if @user.update_attributes(params[:user])
          format.html { redirect_to @user, notice: 'User profile was successfully updated.' }
        else
          format.html { render action: "edit" }
        end
      end
    end

    def destroy
      @user.destroy
      redirect_to users_url
    end

    def become
      sign_in!(@user)
      redirect_to request.referrer
    end

    def make_admin
      if @user.update_attribute(:is_administrator, true)
        redirect_to request.referrer, notice: 'User successfully updated.'
      else
        redirect_to request.referrer, alert: 'Unable to update user.'
      end
    end

  protected

    def get_user
      @user = User.find(params[:id])
    end

  end
end
