class SignupController < ApplicationController

  skip_before_filter :authenticate_user!, only: [:start, :verify_email,
                                                 :check_pin, :password, :check_token, :profile, :social] # TODO change
  skip_before_filter :finish_sign_up

  fine_print_skip :general_terms_of_use, :privacy_policy

  helper_method :saved_email, :saved_role, :instructor_has_selected_subject

  before_filter :restart_if_missing_info, only: [:verify_email, :password]  # TODO spec me

  before_filter :transfer_signup_contact_info, only: [:profile], if: -> { request.get? }


  include SignUpState

  def start
    if request.post?
      handle_with(SignupStart,
                  existing_signup_contact_info: saved_signup_contact_info,
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
                  signup_contact_info: saved_signup_contact_info,
                  success: lambda do
                    redirect_to action: :password
                  end,
                  failure: lambda do
                    render :verify_email
                  end)
    end
  end

  def check_pin

  end

  def check_token
    raise "not yet implemented"
  end

  def password
    @errors ||= env['errors']

    if !current_user.is_anonymous? &&
       current_user.authentications.any?{ |auth| auth.provider == 'identity' }
      security_log :sign_up_failed
      redirect_to root_path, alert: I18n.t(:"controllers.signup.already_have_username_and_password")
    else
      store_fallback
    end
  end

  def profile
    if request.post?
      handler = case saved_role
      when /student/i
        SignupProfileStudent
      else
        SignupProfileInstructor
      end

      handle_with(handler,
                  contracts_required: !contracts_not_required(
                    client_id: request['client_id'] || session['client_id']
                  ),
                  role: saved_role,
                  success: lambda do
                    clear_signup_state
                    redirect_back
                  end,
                  failure: lambda do
                    render :profile
                  end)
    end
  end

  # TODO change all blah and submit_blah actions to blah with switch on GET and POST

  def social
    if request.post?
      handle_with(SignupSocial,
                  contracts_required: !contracts_not_required,
                  success: lambda do
                    set_last_signin_provider(current_user.authentications.first.provider)
                    security_log :sign_up_successful
                    redirect_back
                  end,
                  failure: lambda do
                    security_log :sign_up_failed
                    render :social, status: 400
                  end)
    end
  end

  protected

  def restart_if_missing_info
    redirect_to signup_path if saved_signup_contact_info.nil? || saved_role.nil?
  end

  def transfer_signup_contact_info
    return if saved_signup_contact_info.nil?

    TransferSignupContactInfo[
      signup_contact_info: saved_signup_contact_info,
      user: current_user
    ]
  end

  def instructor_has_selected_subject(key)
    params[:profile] && params[:profile][:subjects] && params[:profile][:subjects][key] == '1'
  end

end
