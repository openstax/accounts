module Admin
  class UsersController < BaseController

    before_filter :get_user, only: [:show, :edit, :update, :destroy]

    def search
      handle_with(Admin::UsersSearch,
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

  protected

    def get_user
      @user = User.find(params[:id])
    end

  end
end