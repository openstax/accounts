class OtherController < Newflow::BaseController

  before_action :newflow_authenticate_user!, only: [
    :profile_newflow, :data_export, :request_account_deletion
  ]
  before_action :ensure_complete_educator_signup, only: :profile_newflow
  before_action :prevent_caching, only: [
    :profile_newflow, :confirm_account_deletion_form, :confirm_account_deletion
  ]

  fine_print_skip :general_terms_of_use, :privacy_policy, only: [
    :confirm_account_deletion_form, :confirm_account_deletion
  ]

  def profile_newflow
    render layout: 'application'
  end

  def data_export
    result = DataExport.call(current_user)
    security_log(:user_data_exported, user: current_user)
    send_data(
      JSON.pretty_generate(result.outputs.data),
      filename: "openstax-data-export-#{Time.now.utc.strftime('%Y%m%d')}.json",
      type: 'application/json',
      disposition: 'attachment'
    )
  end

  def request_account_deletion
    handle_with(
      RequestAccountDeletion,
      success: lambda {
        security_log(:account_deletion_requested, user: current_user)
        flash[:notice] = I18n.t(:'account_deletion.email_sent')
        redirect_to profile_newflow_path
      },
      failure: lambda {
        code = @handler_result.errors.first&.code
        security_log(:account_deletion_request_failed, user: current_user, reason: code)
        flash[:alert] = I18n.t(:'account_deletion.request_failed')
        redirect_to profile_newflow_path
      }
    )
  end

  def confirm_account_deletion_form
    @token = params[:token]
    user = User.find_by(account_deletion_token: @token) if @token.present?

    if user.nil? || user.account_deletion_token_expired?
      flash[:alert] = I18n.t(:'account_deletion.invalid_or_expired_link')
      redirect_to(signed_in? ? profile_newflow_path : newflow_login_path) and return
    end

    render layout: 'application'
  end

  def confirm_account_deletion
    handle_with(
      ConfirmAccountDeletion,
      success: lambda {
        user = @handler_result.outputs.user
        security_log(:account_deleted, user: user)
        sign_out! if signed_in?
        redirect_to newflow_login_path, notice: I18n.t(:'account_deletion.success')
      },
      failure: lambda {
        flash[:alert] = I18n.t(:'account_deletion.invalid_or_expired_link')
        redirect_to newflow_login_path
      }
    )
  end

  def exit_accounts
    if (redirect_param = extract_params(request.referrer)[:r])
      if Host.trusted?(redirect_param)
        redirect_to(redirect_param)
      else
        raise Lev::SecurityTransgression
      end
    elsif !signed_in? && (redirect_uri = extract_params(stored_url)[:redirect_uri])
      redirect_to(redirect_uri)
    else
      redirect_back # defined in the `action_interceptor` gem
    end
  end

  private

  def ensure_complete_educator_signup
    return if current_user.student?

    if decorated_user.incomplete_step_3?
      security_log(:educator_resumed_signup_flow, message: 'User needs to complete SheerID verification. Redirecting.')
      redirect_to(educator_sheerid_form_path)
    elsif decorated_user.incomplete_step_4?
      security_log(:educator_resumed_signup_flow, message: 'User needs to complete instructor profile. Redirecting.')
      redirect_to(educator_profile_form_path)
    end
  end

end
