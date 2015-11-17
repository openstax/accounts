class RemoteController < ApplicationController

  skip_before_filter :authenticate_user!, only: [:iframe, :start_login]
  skip_before_filter :registration,       only: [:iframe]
  skip_before_filter :expired_password,   only: [:iframe]

  before_filter :validate_iframe_parent, :only=>:iframe

  layout false

  # contains a bare-bones HTML file with iframe
  def iframe
  end

  # The first step in commencing a login.
  # Counter-intuitively, the iframe is opened at accounts so that it can
  # communicate between pages due to matching same-origin policy.
  # Then when the parent signals to start loggigng in,
  # it redirects to the client site so it can start the oauth request.
  #   The client site will then redirect back with oauth request params.
  # Login then comences. Once it completes, we once again redirect back
  # to the client site where it can relay tokens or whatever
  def start_login
    store_iframe_session
    redirect_to params[:start]
  end

  # Logout works like logging in except the account is first logged out
  # The login page is then displayed and the flow is identical to login
  def start_logout
    store_iframe_session
    redirect_to logout_url
  end

  # view contains html/javascript to redirect to client url
  def finish_login
    # clear iframe flag in case the user loads via a regular window later
    session.delete(:from_iframe)
    @return_to_url = stored_url
  end

  private

  # store the url that we are going to redirect to
  # This way we can redirect back to it once login is complete
  def store_iframe_session
    session[:from_iframe] = true
    store_url(url: params[:start])
  end

  def validate_iframe_parent
    @iframe_parent = params[:parent]
    valid_origins = SECRET_SETTINGS[:valid_iframe_origins] || []
    unless valid_origins.any?{|origin| @iframe_parent =~ /^#{origin}/ }
      raise SecurityTransgression.new("#{@iframe_parent} is not allowed to iframe content")
    end
  end

end
