class IdentitiesController < ApplicationController

  skip_before_filter :authenticate_user!, :expired_password, :finish_sign_up,
                     only: [:reset_password]

  fine_print_skip :general_terms_of_use, :privacy_policy,
                  only: [:reset_password]

  def update
    handle_with(IdentitiesUpdate,
                success: lambda { render status: :accepted, text: 'Password changed' },
                failure: lambda {
                  render status: 400, text: @handler_result.errors.map(&:message).to_sentence
                })
  end

  def reset_password
    if !current_user.is_anonymous?
      if current_user.identity.nil?
        flash[:alert] = "You cannot reset your password because your account does not have a password."
        redirect_to profile_path
        return
      end

      if current_user.identity.password_expired?
        store_fallback key: :password_return_to
        flash[:alert] = 'Your password has expired. Please enter a new password.'
      end
    end
    handle_with(IdentitiesResetPassword,
                success: lambda {
                  return if !request.post?
                  sign_in! @handler_result.outputs[:identity].user
                  redirect_back key: :password_return_to,
                                notice: 'Your password has been reset successfully! You are now signed in.'
                },
                failure: lambda {
                  render :reset_password, status: 400
                })
  end


  def destroy
    handle_with(AuthenticationDelete,
                success: lambda { render status: :ok, text: "#{params[:provider].titleize} removed" },
                failure: lambda {
                  render status: 400, text: @handler_result.errors.map(&:message).to_sentence
                })
  end

end
