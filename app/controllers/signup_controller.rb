class SignupController < ApplicationController

  PROFILE_TIMEOUT = 30.minutes

  skip_before_filter :authenticate_user!,
                     only: [:start, :verify_email, :verify_by_token, :password, :social, :profile]

  skip_before_filter :complete_signup_profile

  fine_print_skip :general_terms_of_use, :privacy_policy

  before_filter :check_ready_for_profile, only: [:profile]

  before_filter :restart_if_missing_signup_state, only: [:verify_email, :password, :social]
  before_filter :exit_signup_if_logged_in, only: [:start, :verify_email, :password, :social, :verify_by_token]
  before_filter :check_ready_for_password_or_social, only: [:password, :social]

  helper_method :signup_email, :instructor_has_selected_subject

  def start
    if request.post?
      handle_with(SignupStart,
                  existing_signup_state: signup_state,
                  return_to: session[:return_to],
                  session: self,
                  success: lambda do
                    save_signup_state(@handler_result.outputs.signup_state)
                    redirect_to action: @handler_result.outputs.next_action
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
                signup_state: signup_state,
                session: self,
                success: lambda do
                  redirect_to action: (signup_state.trusted_student? ? :profile : :password)
                end,
                failure: lambda do
                  @handler_result.errors.each do | error |  # TODO move to view?
                    error.message = I18n.t(:"signup.verify_email.#{error.code}", default: error.message)
                  end
                  render :verify_email
                end)
  end

  def verify_by_token
    handle_with(SignupVerifyByToken,
                session: self,
                success: lambda do
                  @handler_result.outputs.signup_state.tap do |state|
                    session[:return_to] = state.return_to
                    save_signup_state(state)
                  end
                  redirect_to action: (signup_state.trusted_student? ? :profile : :password)
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
                  success: lambda do
                    clear_signup_state
                    if current_user.student? || current_user.created_from_trusted_data?
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
      redirect_to root_path, alert: t(:"signup.profile.timeout")
    end

    true
  end

  def fail_signup
    clear_signup_state
    raise SecurityTransgression
  end

  def restart_if_missing_signup_state
    redirect_to signup_path if signup_state.nil?
  end

  def check_ready_for_password_or_social
    if signup_state.nil?
      redirect_to action: :start
    elsif !signup_state.verified?
      redirect_to action: :verify_email
    else
      true
    end
  end

  def instructor_has_selected_subject(key)
    params[:profile] && params[:profile][:subjects] && params[:profile][:subjects][key] == '1'
  end

  def exit_signup_if_logged_in
    redirect_to(root_path, notice: (I18n.t :"signup.exit_if_logged_in.already_logged_in")) if signed_in?
  end

end
