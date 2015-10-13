class RemoteController < ApplicationController

  skip_before_filter :authenticate_user!, only: [:iframe, :v1]
  skip_before_filter :registration,       only: [:iframe, :v1]
  skip_before_filter :expired_password,   only: [:iframe, :v1]

  layout false

  def iframe
    render :layout=>false
  end


  # The JS loader script.
  # By using a templated version, it can be customized based on the
  # caller's access
  def v1
    respond_to do |format|
      format.js
    end
  end

end
