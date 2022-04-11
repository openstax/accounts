class BaseController < ApplicationController

  include ApplicationHelper
  include AuthenticateMethods

  layout 'newflow_layout'

  skip_before_action :authenticate_user!

  before_action :set_active_banners

  protected #################

  def decorated_user
    EducatorSignupFlowDecorator.new(current_user, action_name)
  end

  def restart_signup_if_missing_unverified_user
    redirect_to signup_path unless unverified_user.present?
  end

  def set_active_banners
    return unless request.get?

    @banners ||= Banner.active
  end

end
