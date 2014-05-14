class UsersController < ApplicationController

  acts_as_interceptor

  add_interceptor(:registration) do
    redirect_to register_path if current_user.is_temp?
  end

  skip_intercept_with self, :registration

  fine_print_skip_signatures :general_terms_of_use,
                             :privacy_policy,
                             only: [:register]

  def register
    if request.put?
      handle_with(UsersRegister,
                  success: lambda { redirect_from :registration },
                  failure: lambda {
                    errors = @handler_result.errors.any?
                    render :register, status: errors ? 400 : 200
                  })
    end
  end

end