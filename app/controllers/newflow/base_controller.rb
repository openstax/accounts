module Newflow
  class BaseController < ApplicationController

    include ApplicationHelper

    layout 'newflow_layout'

    skip_before_action :authenticate_user!

    before_action :set_active_banners

    protected #################

    def decorated_user
      EducatorSignupFlowDecorator.new(current_user, action_name)
    end

    def restart_signup_if_missing_unverified_user
      # No unverified address means there is nothing for the PIN form to confirm,
      # so send them back to signup rather than into a form that cannot succeed.
      redirect_to newflow_signup_path unless unverified_user.present? && unverified_email_address.present?
    end

    def set_active_banners
      return unless request.get?

      @banners ||= Banner.active
    end

  end
end
