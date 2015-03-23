class StaticPagesController < ApplicationController
  skip_before_filter :authenticate_user!,
                     only: [:api, :copyright, :home, :status]

  fine_print_skip :general_terms_of_use, :privacy_policy,
                  only: [:api, :copyright, :home, :status]

  skip_protect_beta :only => [:status]

  layout :resolve_layout

  def api
  end

  def copyright
  end

  def home
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
