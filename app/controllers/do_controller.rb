# A controller for miscellaneous actions (normally non GETs)
#
class DoController < ApplicationController

  skip_before_filter :authenticate_user!, only: [:confirm_email, :reset_password]

  def confirm_email
    handle_with(ConfirmEmail,
                complete: lambda {
                  render :confirm_email, status: @handler_result.errors.any? ? 400 : 200
                })
  end

  def reset_password
    handle_with(ResetPassword,
                success: lambda {
                  return_to = session.delete(:return_to)
                  if return_to.present?
                    redirect_to return_to
                  else
                    render :reset_password, status: 200
                  end
                },
                failure: lambda {
                  render :reset_password, status: 400
                })
  end

end
