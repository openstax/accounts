class IdentitiesController < ApplicationController

  include RequireRecentSignin

  skip_before_action :authenticate_user!, only: [:reset, :add]

  fine_print_skip :general_terms_of_use, :privacy_policy, only: [:reset]

  before_action :allow_iframe_access

  def reset
    set_password(kind: :reset)
  end

  def add
    set_password(kind: :add)
  end

  def continue
    redirect_back(fallback_location: profile_path)
  end

  protected

  def set_password(kind:)
    if request.get?
      handle_with(LogInByToken,
                  user_state: self,
                  success: lambda do
                    case kind
                    when :add
                      redirect_to action: :reset if current_user.identity.present? &&
                      !current_page?(password_reset_path)
                    when :reset
                      redirect_to action: :add if current_user.identity.nil? &&
                      !current_page?(password_add_path)
                    end
                  end,
                  failure: -> {
                    render status: :bad_request
                  })
    elsif request.post?
      if current_user.is_anonymous?
        raise Lev::SecurityTransgression
      else
        handle_with(IdentitiesSetPassword,
                    success: lambda do
                      security_log :password_reset
                      redirect_to action: "#{kind}_success".to_sym
                    end,
                    failure: lambda do
                      security_log :password_reset_failed
                      render kind, status: :bad_request
                    end)
      end
    end

  end

end
