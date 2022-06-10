class StaticPagesController < ApplicationController
  def api
  end

  def copyright
  end

  def home
    flash.keep # keep notices and errors through to the redirects below

    signed_in? ? redirect_to(profile_path) : redirect_to(login_path)
  end
end
