class StaticPagesController < ApplicationController
  skip_before_filter :authenticate_user!,
                     only: [:api, :copyright, :home, :status]

  skip_before_filter :registration,
                     only: [:api, :copyright, :home, :status, :verification_sent]

  fine_print_skip :general_terms_of_use, :privacy_policy,
                  only: [:api, :copyright, :home, :status, :verification_sent]

  skip_protect_beta :only => [:status]

  layout :resolve_layout

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

  def verification_sent
  end

  # Used by AWS (and others) to make sure the site is still up.
  def status
    head :ok
  end

protected

  def resolve_layout
    'home' == action_name ? 'application_home_page' : 'application_body_only'
  end
end
