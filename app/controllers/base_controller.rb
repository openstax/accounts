class BaseController < ApplicationController

  include ApplicationHelper

  layout 'newflow_layout'

  before_action :set_active_banners

  protected

  def set_active_banners
    return unless request.get?

    @banners ||= Banner.active
  end

end
