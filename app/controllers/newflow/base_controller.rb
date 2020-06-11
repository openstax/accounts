module Newflow
  class BaseController < ApplicationController
    include ApplicationHelper

    layout 'newflow_layout'

    skip_before_action :authenticate_user!

    before_action :set_active_banners

    protected #################

    def set_active_banners
      return unless request.get?

      @banners ||= Banner.active
    end
  end
end
