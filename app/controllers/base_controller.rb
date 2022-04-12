class BaseController < ApplicationController

  layout 'newflow_layout'

  skip_before_action :authenticate_user!

  protected

  def decorated_user
    EducatorSignupFlowDecorator.new(current_user, action_name)
  end
end
