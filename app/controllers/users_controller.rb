class UsersController < ApplicationController

  fine_print_skip_signatures :general_terms_of_use,
                             :privacy_policy,
                             only: [:register]

  def register
    if request.put?
      handle_with(UsersRegister,
                  success: lambda { redirect_to return_to_app_path },
                  failure: lambda {
                    errors = @handler_result.errors.any?
                    render :register, status: errors ? 400 : 200
                  })
    end
  end

end