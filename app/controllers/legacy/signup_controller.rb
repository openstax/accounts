module Legacy
  class SignupController < ApplicationController

    PROFILE_TIMEOUT = 30.minutes

    before_action :redirect_to_newflow_if_enabled, only: [:start]

    skip_before_action :authenticate_user!,
                      only: [:start, :verify_email, :verify_by_token, :password, :social, :profile]

    skip_before_action :complete_signup_profile

    fine_print_skip :general_terms_of_use, :privacy_policy

    before_action :check_ready_for_profile, only: [:profile]

    before_action :restart_if_missing_pre_auth_state, only: [:verify_email, :password, :social]
    before_action :exit_signup_if_logged_in, only: [:start, :verify_email, :password, :social, :verify_by_token]
    before_action :check_ready_for_password_or_social, only: [:password, :social]

    helper_method :signup_email, :instructor_has_selected_subject

    def start
      if request.post?
        handle_with(SignupStart,
                    existing_pre_auth_state: pre_auth_state,
                    return_to: session[:return_to],
                    session: self,
                    success: lambda do
                      save_pre_auth_state(@handler_result.outputs.pre_auth_state)
                      redirect_to action: :verify_email
                    end,
                    failure: lambda do
                      @role = params[:signup].try(:[],:role)
                      @signup_email = params[:signup].try(:[],:email)
                      render :start
                    end)
      else
        @role = signup_role # select whatever value the role was previously set to
      end
    end

    def verify_email
      render and return if request.get?

      handle_with(SignupVerifyEmail,
                  pre_auth_state: pre_auth_state,
                  session: self,
                  success: lambda do
                    redirect_to action: (pre_auth_state.signed_student? ? :profile : :password)
                  end,
                  failure: lambda do
                    @handler_result.errors.each do | error |  # TODO move to view?
                      error.message = I18n.t(:"legacy.signup.verify_email.#{error.code}", default: error.message)
                    end
                    render :verify_email
                  end)
    end

    def verify_by_token
      handle_with(SignupVerifyByToken,
                  session: self,
                  success: lambda do
                    @handler_result.outputs.pre_auth_state.tap do |state|
                      session[:return_to] ||= state.return_to
                      save_pre_auth_state(state)
                    end
                    redirect_to action: (pre_auth_state.signed_student? ? :profile : :password)
                  end,
                  failure: lambda do
                    # TODO spec this and set an error message
                    redirect_to action: :start
                  end)
    end

    def password; end
    def social; end

    def profile
      if request.post?
        handler = case current_user.role
        when "student"
          SignupProfileStudent
        when "instructor"
          SignupProfileInstructor
        else
          SignupProfileOther
        end

        handle_with(handler,
                    contracts_required: !contracts_not_required,
                    client_app: get_client_app,
                    success: lambda do
                      clear_pre_auth_state
                      if current_user.student? || current_user.created_from_signed_data?
                        redirect_back
                      else
                        redirect_to action: :instructor_access_pending
                      end
                    end,
                    failure: lambda do
                      render :profile
                    end)
      else
        params[:profile] = {
          school: current_user.self_reported_school
        }
      end
    end

    def instructor_access_pending
      redirect_back if request.post?
    end

    protected

    def check_ready_for_profile
      # Only expect signed in, needs_profile users, who have a verified email
      fail_signup if !signed_in? ||
                    !current_user.is_needs_profile? ||
                    current_user.contact_infos.verified.none?

      if last_login_is_older_than?(PROFILE_TIMEOUT)
        sign_out!
        redirect_to root_path, alert: t(:"legacy.signup.profile.timeout")
      end

      true
    end

    def fail_signup
      clear_pre_auth_state
      raise SecurityTransgression
    end

    def restart_if_missing_pre_auth_state
      redirect_to signup_path(bpff: 9) if pre_auth_state.nil?
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
