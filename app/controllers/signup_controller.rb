
class SignupController < ApplicationController

  skip_before_filter :authenticate_user!, only: [:start, :submit_email, :verify_email,
                                                 :check_pin, :password, :check_token] # TODO change
  skip_before_filter :finish_sign_up

  fine_print_skip :general_terms_of_use, :privacy_policy

  helper_method :saved_email, :saved_role

  def start
  end

  def submit_email
    handle_with(SignupSubmitEmail,
                existing_signup_contact_info: saved_signup_contact_info,
                success: lambda do
                  session[:signup] = {role: @handler_result.outputs.role,
                                      ci_id: @handler_result.outputs.signup_contact_info.id }
                  redirect_to action: :verify_email
                end,
                failure: lambda do
                  render :start
                end)
  end

  def verify_email

  end

  def check_pin
    handle_with(SignupCheckPin,
                signup_contact_info: saved_signup_contact_info,
                success: lambda do
                  redirect_to action: :password
                end,
                failure: lambda do
                  render :verify_email
                end)
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

  def submit_password
    handle_with(SignupPassword, # TODO make this consistent with action name
                signup_contact_info: saved_signup_contact_info,
                success: lambda do
                  redirect_to action: :profile
                end,
                failure: lambda do
                  render :password
                end)
  end

  def profile

  end

  def submit_profile
        handle_with(SignupSubmitProfile,
                contracts_required: !contracts_not_required(
                  client_id: request['client_id'] || session['client_id']
                ),
                success: lambda do
                  redirect_to action: :profile
                end,
                failure: lambda do
                  render :password
                end)

  end

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

  def finish
    handle_with(SignupFinish,
                success: lambda do
                  session.delete(:signup)
                end,
                failure: lambda do

                end)
  end

  protected

  def saved_role
    session[:signup].try(:[],'role')
  end

  def saved_signup_contact_info
    @saved_signup_contact_info ||= SignupContactInfo.find_by(id: session[:signup].try(:[],'ci_id'))
  end

  def saved_email
    @saved_email ||= saved_signup_contact_info.try(:value)
  end

end
