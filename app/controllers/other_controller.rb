class OtherController < Newflow::BaseController

  before_action :newflow_authenticate_user!, only: [:profile_newflow, :update]
  before_action :ensure_complete_educator_signup, only: :profile_newflow
  before_action :prevent_caching, only: [:profile_newflow, :update]

  def profile_newflow
    render layout: 'application'
  end

  # Backs the inline-editable name/username fields on the newflow profile page
  # (app/views/newflow/base/profile_newflow.html.erb sets
  # $.fn.editable.defaults.url = profile_path / ajaxOptions.type = "PUT"). Moved
  # here from the retired Legacy::UsersController#update -- this AJAX endpoint is
  # not legacy-only, the current newflow profile page depends on it directly.
  def update
    OSU::AccessPolicy.require_action_allowed!(:update, current_user, current_user)

    respond_to do |format|
      format.json do
        if params[:value].is_a?(String) && !ALLOWED_STRING_UPDATE_FIELDS.include?(params[:name])
          render json: { error: 'invalid field' }, status: :bad_request and return
        end

        if current_user.update(user_params)
          security_log :user_updated, user_params: user_params

          render json: { full_name: current_user.full_name }, status: :ok
        else
          render json: current_user.errors.full_messages.first, status: :unprocessable_entity
        end
      end
    end
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

  # Single-field x-editable inline update on the profile page (see
  # app/views/newflow/base/profile_newflow.html.erb) only ever submits
  # {name: "username", value: <string>} -- name/title/suffix use the
  # object branch below via OX.Profile.Name.editable. Whitelisted here so a
  # crafted {name: <any column>, value: <string>} PUT can't mass-assign
  # arbitrary User attributes (e.g. role, faculty_status) through the same
  # self-update AccessPolicy check.
  ALLOWED_STRING_UPDATE_FIELDS = %w[username].freeze

  def user_params
    params[:value].is_a?(String) ? \
      {params[:name] => params[:value]} : \
      params.require(:value).permit(:title, :first_name, :last_name, :suffix).to_h
  end

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
