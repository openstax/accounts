module Dev
  class UsersController < Dev::BaseController

    def create
      handle_with(Dev::UsersCreate)
    end

    def generate
      handle_with(Dev::UsersGenerate)
    end

  end
end
