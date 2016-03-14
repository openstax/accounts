
class SignupController < ApplicationController

  skip_before_filter :authenticate_user!

  fine_print_skip :general_terms_of_use, :privacy_policy

  def password

  end

  def social
    if request.post?
      handle_with(UsersRegister,
                  contracts_required: !contracts_not_required,
                  success: lambda {
                    redirect_back
                  },
                  failure: lambda {
                    errors = @handler_result.errors.any?
                    render :social, status: errors ? 400 : 200
                  })
    end
  end

end
