class UsersController < ApplicationController

  skip_before_filter :authenticate_user!, only: [:become]

  fine_print_skip_signatures :general_terms_of_use,
                             :privacy_policy,
                             only: [:register, :become]

  def register
    if request.put?
      handle_with(UsersRegister,
                  success: lambda { redirect_to sessions_return_to_app_path },
                  failure: lambda {
                    errors = @handler_result.errors.any?
                    render :register, status: errors ? 400 : 200
                  })
    end
  end

  def become
    raise SecurityTransgression unless !Rails.env.production? || current_user.is_admin?
    sign_in(User.find(params[:id]))
    redirect_to request.referrer
  end

end