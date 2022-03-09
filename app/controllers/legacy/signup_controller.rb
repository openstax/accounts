module Legacy
  class SignupController < ApplicationController

    include LegacyHelper

    before_action :redirect_to_newflow_if_enabled, only: [:start]

    skip_before_action :authenticate_user!,
                      only: [:start, :verify_email, :password, :social, :profile]

    skip_before_action :complete_signup_profile

    fine_print_skip :general_terms_of_use, :privacy_policy

    before_action :restart_if_missing_pre_auth_state, only: [:verify_email, :password, :social]
    before_action :exit_signup_if_logged_in, only: [:start, :verify_email, :password, :social]
    before_action :check_ready_for_password_or_social, only: [:password, :social]

    helper_method :signup_email, :instructor_has_selected_subject

    def start; end
    def verify_email; end
    def password; end
    def social; end
    def profile; end

    def instructor_access_pending
      redirect_back if request.post?
    end

    protected

    def restart_if_missing_pre_auth_state
      redirect_to signup_path(set_param_to_permit_legacy_flow) if pre_auth_state.nil?
    end

    def check_ready_for_password_or_social
      if pre_auth_state.nil?
        redirect_to action: :start
      elsif !pre_auth_state.is_contact_info_verified?
        redirect_to action: :verify_email
      else
        true
      end
    end

    def instructor_has_selected_subject(key)
      params[:profile] && params[:profile][:subjects] && params[:profile][:subjects][key] == '1'
    end

    def exit_signup_if_logged_in
      redirect_to(root_path, notice: (I18n.t :"legacy.signup.exit_if_logged_in.already_logged_in")) if signed_in?
    end

  end
end
