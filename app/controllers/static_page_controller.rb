class StaticPageController < ApplicationController
  skip_before_filter :authenticate_user!, only: [:home, :copyright]

  layout :resolve_layout

protected

  def resolve_layout
    'home' == action_name ? 'application_home_page' : 'application_body_only'
  end
end
