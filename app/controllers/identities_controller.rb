class IdentitiesController < ApplicationController

  include RequireRecentSignin

  skip_before_filter :authenticate_user!, :expired_password, :finish_sign_up,
                     only: [:reset_password, :send_password_reset, :sent_password_reset, :add_password, :send_password_add, :sent_password_add]

  fine_print_skip :general_terms_of_use, :privacy_policy,
                  only: [:reset_password, :send_password_reset, :sent_password_reset, :add_password, :send_password_add, :sent_password_add]  # TODO dry up these filters

  before_filter :reauthenticate_user_if_signin_is_too_old!,
                 except: [:reset_password, :send_password_reset, :sent_password_reset, :add_password, :send_password_add, :sent_password_add]

  def update  # TODO only used for password add/change from profile page -- rename to something more specific
    handle_with(IdentitiesUpdate,
                success: lambda  do
                  security_log :password_updated
                  render status: :accepted,
                         text: (I18n.t :"controllers.identities.password_changed")
                end,
                failure: lambda do
                  render status: 422, text: @handler_result.errors.map(&:message).to_sentence
                end)
  end

  def reset_password
    set_password(kind: :reset)
  end

  def add_password
    set_password(kind: :add)
  end

  # TODO dry up this code!

  def send_password_reset
    send_password_email(kind: :reset, success_redirect: :sent_password_reset)
  end

  def send_password_add
    send_password_email(kind: :add, success_redirect: :sent_password_add)
  end

  def sent_password_reset; end
  def sent_password_add; end

  protected

  def send_password_email(kind:, success_redirect:)
    handle_with(IdentitiesSendPasswordEmail,
                kind: kind,
                user: User.find(get_login_state[:matching_user_ids].first),
                success: lambda do
                  redirect_to success_redirect
                end,
                failure: lambda do
                  redirect_to authenticate_path # TODO spec this or remove and switch success to complete
                end)
  end

  def set_password(kind:)
    if request.get?
      handle_with(LogInByToken,
                  user_state: self,
                  success: lambda do
                    security_log :sign_in_successful, {type: 'token'}
                    case kind
                    when :add
                      redirect_to :reset_password if current_user.identity.present?
                    when :reset
                      redirect_to :add_password if current_user.identity.nil?
                    end
                  end,
                  failure: ->{})
    elsif request.post?
      handle_with(IdentitiesSetPassword,
                  success: lambda do
                    security_log :password_reset
                    redirect_back
                  end,
                  failure: lambda do
                    security_log :password_reset_failed
                    action = "#{kind}_password".to_sym
                    render action, status: 400
                  end)
    end

    # MAJOR TODO: figure out where this password expired stuff fits in
    #
    # if !current_user.is_anonymous?
    #   if current_user.identity.password_expired?
    #     security_log :password_expired
    #     store_fallback key: :password_return_to
    #     flash[:alert] = I18n.t :"controllers.identities.password_expired"
    #   end
    # end
  end

end
