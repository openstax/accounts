class StaticPageController < ApplicationController
  skip_before_filter :authenticate_user!, only: [:home, :copyright, :api]

  fine_print_skip_signatures :general_terms_of_use,
                             :privacy_policy,
                             only: [:api, :copyright, :home]

  layout :resolve_layout

protected

  def resolve_layout
    'home' == action_name ? 'application_home_page' : 'application_body_only'
  end
end
