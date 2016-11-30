class SignupController < ApplicationController

  skip_before_filter :authenticate_user!,
                     only: [:start, :verify_email, :verify_by_token, :password, :social, :profile]

  skip_before_filter :finish_sign_up

  fine_print_skip :general_terms_of_use, :privacy_policy

  before_filter :check_ready_for_profile, only: [:profile]

  # TODO spec this and maybe make more specific to what each action needs (including :profile, which needs role)
  before_filter :restart_if_missing_info, only: [:verify_email, :password, :social, :verify_by_token]

  # TODO spec this
  before_filter :exit_signup_if_logged_in, only: [:start, :verify_email, :password, :social, :verify_by_token]

  before_filter :require_verified_signup_contact_info, only: [:password, :social]

  helper_method :signup_email, :signup_role, :instructor_has_selected_subject

  def start
    if request.post?
      handle_with(SignupStart,
                  existing_signup_contact_info: signup_contact_info,
                  success: lambda do
                      save_signup_state(
                        role: @handler_result.outputs.role,
                        signup_contact_info_id: @handler_result.outputs.signup_contact_info.id
                      )
                      redirect_to action: :verify_email
                  end,
                  failure: lambda do
                    save_signup_state(role: params[:signup][:role], signup_contact_info_id: nil)
                    @handler_result.errors.each do | error |
                      error.message = I18n.t("signup.start.#{error.code}", signin_url: signin_url)
                    end
                    render :start
                  end)
    end
  end

  def verify_email  # TODO maybe rename just `verify`
    if request.post?
      handle_with(SignupVerifyEmail,
                  signup_contact_info: signup_contact_info,
                  success: lambda do
                    redirect_to action: :password
                  end,
                  failure: lambda do
                    @handler_result.errors.each do | error |
                      error.message = I18n.t("signup.verify_email.#{error.code}")
                    end
                    render :verify_email
                  end)
    end
  end

  def verify_by_token
    handle_with(SignupVerifyByToken,
                success: lambda do
                  redirect_to action: :password
                end,
                failure: lambda do
                  raise "not yet implemented"
                end)
  end

  def password; end
  def social; end

  def profile
    if request.get?
      if signup_contact_info.present?
        TransferSignupContactInfo[
          signup_contact_info: signup_contact_info,
          user: current_user
        ]
      end

      # Should have a verified email by now
      fail_signup if current_user.contact_infos.verified.none?
    elsif request.post?
      handler = case signup_role
      when /student/i
        SignupProfileStudent
      when /instructor/i
        SignupProfileInstructor
      else
        SignupProfileOther
      end

      handle_with(handler,
                  contracts_required: !contracts_not_required(
                    client_id: request['client_id'] || session['client_id']
                  ),
                  role: signup_role,
                  success: lambda do
                    is_student = signup_role == "student"
                    clear_signup_state

                    if is_student
                      redirect_back
                    else
                      redirect_to action: :instructor_access_pending
                    end
                  end,
                  failure: lambda do
                    render :profile
                  end)
    end
  end

  def instructor_access_pending
    redirect_back if request.post?
  end

  protected

  def check_ready_for_profile
    # Only expect signed in, needs_profile users
    fail_signup if !signed_in? || !current_user.is_needs_profile?
    true
  end

  def fail_signup
    signup_contact_info.try(:destroy)
    clear_signup_state
    raise SecurityTransgression
  end

  def restart_if_missing_info
    redirect_to signup_path if signup_contact_info.nil? || signup_role.nil?
  end

  def require_verified_signup_contact_info
    if signup_contact_info.nil?
      redirect_to action: :start
    elsif !signup_contact_info.verified?
      redirect_to action: :verify_email
    else
      true
    end
  end

  def instructor_has_selected_subject(key)
    params[:profile] && params[:profile][:subjects] && params[:profile][:subjects][key] == '1'
  end

  def exit_signup_if_logged_in
    # TODO add a flash[:alert] like "You have already signed up"
    redirect_to root_path if signed_in?
  end

end
