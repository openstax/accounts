class SignupController < ApplicationController

  skip_before_filter :authenticate_user!, only: [:start, :verify_email, :check_token, :password, :social]

  skip_before_filter :finish_sign_up

  fine_print_skip :general_terms_of_use, :privacy_policy

  # TODO spec this and maybe make more specific to what each action needs (including :profile, which needs role)
  before_filter :restart_if_missing_info, only: [:verify_email, :password, :social, :check_token]

  # TODO spec this
  before_filter :exit_signup_if_logged_in, only: [:start, :verify_email, :password, :social, :check_token]

  before_filter :transfer_signup_contact_info, only: [:profile], if: -> { request.get? }

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

  def verify_email
    if request.post?
      handle_with(SignupVerifyEmail,
                  signup_contact_info: signup_contact_info,
                  success: lambda do
                    redirect_to action: :password
                  end,
                  failure: lambda do
                    render :verify_email
                  end)
    end
  end

  def check_token
    raise "not yet implemented"
  end

  def password; end
  def social; end

  def profile
    if request.post?
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
                    clear_signup_state
                    # TODO send faculty (or admin who selected faculty) to verification screen
                    redirect_back
                  end,
                  failure: lambda do
                    render :profile
                  end)
    end
  end

  protected

  def restart_if_missing_info
    redirect_to signup_path if signup_contact_info.nil? || signup_role.nil?
  end

  def transfer_signup_contact_info
    return if signup_contact_info.nil?

    TransferSignupContactInfo[
      signup_contact_info: signup_contact_info,
      user: current_user
    ]
  end

  def instructor_has_selected_subject(key)
    params[:profile] && params[:profile][:subjects] && params[:profile][:subjects][key] == '1'
  end

  def exit_signup_if_logged_in
    # TODO add a flash[:alert] like "You have already signed up"
    redirect_to root_path if signed_in?
  end

end
