class EducatorSignupFlowDecorator

  include Rails.application.routes.url_helpers

  attr_reader :user, :current_step

  def initialize(user, current_step)
    @user = user
    @current_step = current_step
  end

  def can_do?(action)
    return false if shouldnt_proceed?

    case action
    when 'redirect_back_upon_login'
      user.is_newflow? && user.is_profile_complete?
    end
  end

  def next_step
    case true
    when current_step == 'login' && !user.is_profile_complete && user.sheerid_verification_id.blank?
      educator_sheerid_form_path
    else
      raise("Next step uncaught in #{self.class.name}")
    end
  end

  private ###################

  def shouldnt_proceed?
    user.student? || !Settings::FeatureFlags.educator_feature_flag
  end

end
