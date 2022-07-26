module Dev
  class UsersController < BaseController

    skip_before_action :authenticate_user!

    def create
      handle_with(Dev::UsersCreate)
    end

    def generate
      handle_with(Dev::UsersGenerate)
    end

  end
end
