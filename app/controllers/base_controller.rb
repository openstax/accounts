class BaseController < ApplicationController

  include ApplicationHelper

  layout 'newflow_layout'

  before_action :set_active_banners

  protected

  def decorated_user
    EducatorSignupFlowDecorator.new(current_user, action_name)
  end

  def restart_signup_if_missing_unverified_user
    redirect_to signup_path unless unverified_user.present?
  end
end
