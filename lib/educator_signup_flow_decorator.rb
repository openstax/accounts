class EducatorSignupFlowDecorator

  include Rails.application.routes.url_helpers

  attr_reader :user, :current_step

  def initialize(user, current_step)
    @user = user
    @current_step = current_step
  end

  def newflow_edu_incomplete_step_3?
    if !user.is_newflow? || user.is_sheerid_unviable?
      return false
    elsif user.sheerid_verification_id.blank? && user.pending_faculty?
      return true
    end
  end

  def newflow_edu_incomplete_step_4?
    return false if !user.is_newflow?

    return true if !user.is_profile_complete?
  end

  def can_do?(action)
    return false if shouldnt_proceed?

    case action
    when 'redirect_back_upon_login'
      user.is_newflow? && user.is_profile_complete?
    when 'educator_sheerid_form'
      # debugger
      (user.no_faculty_info? || user.pending_faculty?) && user.sheerid_verification_id.blank?
    when 'educator_signup_form'
      user.is_anonymous?
    when 'educator_signup'
      user.is_anonymous?
    when 'educator_email_verification_form'
      user.is_anonymous?
    else
      true
    end
  end

  # The next path or page to go to
  def next_step
    case true
    when current_step == 'login' && !user.is_profile_complete && user.sheerid_verification_id.blank?
      educator_sheerid_form_path
    when current_step == 'educator_sheerid_form'
      if user.confirmed_faculty? || user.rejected_faculty? || user.sheerid_verification_id.present?
        # debugger # educator_profile_form_path(request.query_parameters)
      end
    when current_step == 'educator_signup_form' && !user.is_anonymous?
        educator_email_verification_form_path
    when current_step == 'educator_email_verification_form' && user.activated?
      if !user.student? && user.activated? && user.pending_faculty && user.sheerid_verification_id.blank?
        educator_sheerid_form_path
      elsif user.activated?
        educator_profile_form_path
      end
    else
      raise("Next step (#{current_step}) uncaught in #{self.class.name}")
    end
  end

  private ###################

  def shouldnt_proceed?
    user.student? || !Settings::FeatureFlags.educator_feature_flag
  end

end
