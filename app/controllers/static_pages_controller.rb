class StaticPagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:api, :copyright, :home]

  fine_print_skip :general_terms_of_use, :privacy_policy, only: [:api, :copyright]

  def api
  end

  def copyright
  end

  def home
    flash.keep # keep notices and errors through to the redirects below

    signed_in? ? redirect_to(profile_path) : redirect_to(login_path)
  end
end
