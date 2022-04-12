# Copyright 2011-2016 Rice University. Licensed under the Affero General Public
# License version 3 or later.  See the COPYRIGHT file for details.

module Admin
  class BaseController < ApplicationController

    layout 'admin'

    include FakeExceptionHelper

    if Rails.env.development?
      skip_before_action :authenticate_user!
    else
      before_action :authenticate_admin!
      before_action :log_out_inactive_admins
    end

    def log_out_inactive_admins
      if current_user.is_administrator? && is_real_production_site?
        if !session[:last_admin_activity].nil? &&
            session[:last_admin_activity].to_time <= 30.minutes.ago
          sign_out!
          authenticate_admin!
        else
          session[:last_admin_activity] = DateTime.now.to_s
        end
      end
    end

    def raise_exception
      raise_fake_exception(params[:type])
    end

  end
end
