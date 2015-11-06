class RemoteController < ApplicationController

  skip_before_filter :authenticate_user!, only: [:iframe, :start_login]
  skip_before_filter :registration,       only: [:iframe]
  skip_before_filter :expired_password,   only: [:iframe]

  before_filter :validate_iframe_parent, :only=>:iframe

  layout false

  def iframe
    session[:from_iframe] = true
    render :layout=>false
  end

  # The first step in commencing a login
  def start_login
    # store the url that we are going to redirect to
    # This way we can redirect back to it once login is complete
    store_url(url: params[:start])
    redirect_to params[:start]
  end

  # view contains html/javascript to deliver the results
  def finish_login
    @return_to_url = stored_url
  end

  private

  def validate_iframe_parent
    @iframe_parent = params[:parent]
    unless SECRET_SETTINGS[:valid_iframe_origins].any?{|origin| @iframe_parent =~ /^#{origin}/ }
      raise SecurityError.new("#{@iframe_parent} is not allowed to iframe content")
    end
  end

end
