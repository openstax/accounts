class RegistrationController < ApplicationController

  skip_before_filter :registration
  fine_print_skip :general_terms_of_use, :privacy_policy

  # Note: this is where email verification used to hook into the login flow.
  def complete
    if current_user.is_activated?
      redirect_back
    elsif request.put?
      handle_with(UsersRegister,
                  contracts_required: !contracts_not_required,
                  success: lambda {
                    redirect_back
                  },
                  failure: lambda {
                    errors = @handler_result.errors.any?
                    render :complete, status: errors ? 400 : 200
                  })
    end
  end

  def verification_pending
    if !current_user.has_emails_but_none_verified?
      flash.keep # "already verified" message
      redirect_to registration_complete_path
    end
  end

  def i_verified
    if current_user.has_emails_but_none_verified?
      redirect_to registration_verification_pending_path,
                  alert: "We haven't seen that you clicked the verification link.  Please try again."
    else
      redirect_to registration_complete_path
    end
  end

end
