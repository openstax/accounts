class UsersController < ApplicationController

  include Interceptor

  intercept_block = lambda { register_path if current_user.is_temp? }

  #intercept ::ApplicationController, &intercept_block
  intercept Doorkeeper::AuthorizationsController, &intercept_block

  fine_print_skip_signatures :general_terms_of_use,
                             :privacy_policy,
                             only: [:register]

  def register
    if request.put?
      handle_with(UsersRegister,
                  success: lambda { redirect_to return_from_registration },
                  failure: lambda {
                    errors = @handler_result.errors.any?
                    render :register, status: errors ? 400 : 200
                  })
    end
  end

end