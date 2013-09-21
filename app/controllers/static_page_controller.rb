class StaticPageController < ApplicationController
  layout :resolve_layout

protected

  def resolve_layout
    'home' == action_name ? 'application_home_page' : 'application_body_only'
  end
end
