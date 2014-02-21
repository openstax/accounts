# A controller for miscellaneous actions (normally non GETs)
#
class DoController < ApplicationController

  skip_before_filter :authenticate_user!, only: [:confirm_email]

  def confirm_email
    handle_with(ConfirmEmail,
                complete: lambda {
                  render :confirm_email, status: @handler_result.errors.any? ? 400 : 200
                })
  end

end
