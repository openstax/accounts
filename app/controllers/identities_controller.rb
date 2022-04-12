class IdentitiesController < ApplicationController

  include RequireRecentSignin

  skip_before_action :authenticate_user!, :check_if_password_expired, :complete_signup_profile,
                    only: [:reset, :send_reset, :add, :send_add]

  fine_print_skip :general_terms_of_use, :privacy_policy,
                  only: [:reset, :send_reset, :add, :send_add,
                        :reset_success, :add_success]

  before_action :allow_iframe_access

  def reset
    set_password(kind: :reset)
  end

  def add
    set_password(kind: :add)
  end

  def send_reset
    send_password_email(kind: :reset)
  end

  def send_add
    send_password_email(kind: :add)
  end

  def continue
    redirect_back(fallback_location: profile_path)
  end

  protected

  def send_password_email(kind:)
    # Can be reached before logged in (can't remember password) or when logged
    # in and asked to reauthenticate and can't remember password.

    user = signed_in? ? current_user :
                        User.find_by(id: get_login_state[:matching_user_ids].try(:first))

    redirect_to(root_path, alert: I18n.t(:'controllers.lost_user')) && return if user.nil?

    handle_with(IdentitiesSendPasswordEmail,
                kind: kind,
                user: user,
                success: lambda do
                  security_log :help_requested, user: user
                  sign_out!
                end,
                failure: lambda do
                  security_log :help_request_failed, user: user
                  redirect_to authenticate_path
                end)
  end

  def set_password(kind:)
    if request.get?
      handle_with(LogInByToken,
                  user_state: self,
                  success: lambda do
                    # This reauthenticate check is only relevant if user was already
                    # logged in before making this request.
                    if user_signin_is_too_old?
                      reauthenticate_user!
                    else
                      case kind
                      when :add
                        redirect_to action: :reset if current_user.identity.present? && !current_page?(password_reset_path)
                      when :reset
                        redirect_to action: :add if current_user.identity.nil? && !current_page?(password_add_path)
                      end
                    end
                  end,
                  failure: -> {
                    render status: 400
                  })
    elsif request.post?
      if current_user.is_anonymous?
        raise Lev::SecurityTransgression
      elsif user_signin_is_too_old?
        # This check again here in case a long time elapsed between the GET and the POST
        reauthenticate_user_if_signin_is_too_old!
      else
        handle_with(IdentitiesSetPassword,
                    success: lambda do
                      security_log :password_reset
                      redirect_to action: "#{kind}_success".to_sym
                    end,
                    failure: lambda do
                      security_log :password_reset_failed
                      render kind, status: 400
                    end)
      end
    end

  end

end
