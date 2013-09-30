# A controller for miscellaneous actions (normally non GETs)
#
class DoController < ApplicationController

  skip_before_filter :authenticate_user!, only: [:confirm_email]

  def confirm_email
    handle_with(ConfirmEmail)
  end

end
