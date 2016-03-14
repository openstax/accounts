class StaticPagesController < ApplicationController
  skip_before_filter :authenticate_user!, only: [:api, :copyright, :home, :status]

  skip_before_filter :registration, only: [:api, :copyright, :status]

  fine_print_skip :general_terms_of_use, :privacy_policy, only: [:api, :copyright, :status]

  skip_protect_beta only: [:status]

  layout 'application'

  def api
  end

  def copyright
  end

  def home
    flash.keep # keep notices and errors through to the redirects below

    if signed_in?
      redirect_to profile_path
    else
      store_url # needed for happy login flow, authenticate_user! does it too
      redirect_to login_path
    end
  end

  # Used by AWS (and others) to make sure the site is still up.
  def status
    head :ok
  end

end
