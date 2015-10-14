class RemoteController < ApplicationController

  skip_before_filter :authenticate_user!, only: [:iframe, :v1]
  skip_before_filter :registration,       only: [:iframe, :v1]
  skip_before_filter :expired_password,   only: [:iframe, :v1]

  before_filter :validate_iframe_parent, :only=>:iframe

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


  private

  def validate_iframe_parent
    @iframe_parent = params[:parent]
    unless SECRET_SETTINGS[:valid_iframe_origins].any?{|origin| @iframe_parent =~ /^#{origin}/ }
      raise SecurityError.new("#{@iframe_parent} is not allowed to iframe content")
    end
  end



end
