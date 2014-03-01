module Dev
  class UsersController < BaseController

    def search
      handle_with(Admin::UsersSearch,
                  complete: lambda { render 'admin/users/search' })
    end

    def create
      handle_with(Dev::UsersCreate)
    end

    def generate
      handle_with(Dev::UsersGenerate)
    end

  end
end
