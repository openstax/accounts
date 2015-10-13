class RemoteController < ApplicationController

  after_filter :set_wideopen_cors
  skip_before_filter :authenticate_user!, only: [:test, :iframe, :login, :cors_preflight_check]
  skip_before_filter :registration,       only: [:test, :iframe, :login, :cors_preflight_check]
  skip_before_filter :expired_password,   only: [:test, :iframe, :login, :cors_preflight_check]

  layout false

  def test
    # TODO: figure out how to return a token when logged in
    p current_user
    render json: { is_logged_in: !current_user.is_anonymous? }
  end

  def iframe
    render :layout=>false
  end

  def login
  end

  def cors_preflight_check
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'POST, GET, OPTIONS'
    headers['Access-Control-Allow-Headers'] = '*'
    headers['Access-Control-Max-Age'] = '1728000'
    render :text => '', :content_type => 'text/plain'
  end

  private

  def set_wideopen_cors
    # TODO: Replace asterisk with list of domains (cnx.org, etc)
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'POST, PUT, DELETE, GET, OPTIONS'
    headers['Access-Control-Request-Method'] = '*'
    headers['Access-Control-Allow-Headers'] = 'Origin, X-Requested-With, Content-Type, Accept, Authorization'
  end

end
