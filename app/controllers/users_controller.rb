class UsersController < ApplicationController

  acts_as_interceptor

  skip_interceptor :registration, only: [:register]

  fine_print_skip_signatures :general_terms_of_use,
                             :privacy_policy,
                             only: [:register]

  def show
    OSU::AccessPolicy.require_action_allowed!(:update, current_user, current_user)
    render :edit
  end

  def update
    
  end

  def register
    if request.put?
      handle_with(UsersRegister,
                  success: lambda { redirect_back },
                  failure: lambda {
                    errors = @handler_result.errors.any?
                    render :register, status: errors ? 400 : 200
                  })
    end
  end

end