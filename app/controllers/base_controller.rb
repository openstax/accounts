class BaseController < ApplicationController

  include ApplicationHelper

  skip_before_action :authenticate_user!

  protected

  def decorated_user
    EducatorSignupFlowDecorator.new(current_user, action_name)
  end

  def restart_signup_if_missing_unverified_user
    redirect_to newflow_signup_path unless unverified_user.present?
  end
end
