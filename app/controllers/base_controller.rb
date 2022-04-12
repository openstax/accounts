class BaseController < ApplicationController

  layout 'newflow_layout'

  skip_before_action :authenticate_user!

  protected

  def decorated_user
    EducatorSignupFlowDecorator.new(current_user, action_name)
  end

  def restart_signup_if_missing_verified_user
    redirect_to signup_path unless unverified_user.present?
  end
end
