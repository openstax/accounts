# Completing a signup profile is not legacy-only: the global
# `complete_signup_profile` before_action (config/initializers/controllers.rb)
# sends ANY signed-in user in the default `needs_profile` state here, whether
# they arrived via the legacy flow, newflow, or Doorkeeper's OAuth authorize
# path. This used to live at Legacy::SignupController#profile; it was moved
# out of the Legacy:: namespace (but keeps its `/signup/profile` URL and
# `signup_profile` route name, and its view at
# app/views/legacy/signup/profile.html.erb) as part of retiring the rest of
# the legacy login/signup controllers, since this piece is still load-bearing.
class SignupProfileController < ApplicationController

  PROFILE_TIMEOUT = 30.minutes

  skip_before_action :authenticate_user!, only: [:profile]

  skip_before_action :complete_signup_profile

  fine_print_skip :general_terms_of_use, :privacy_policy

  before_action :check_ready_for_profile, only: [:profile]

  helper_method :instructor_has_selected_subject

  def profile
    if request.post?
      handler = case current_user.role
      when "student"
        SignupProfileStudent
      when "instructor"
        SignupProfileInstructor
      else
        SignupProfileOther
      end

      handle_with(handler,
                  contracts_required: !contracts_not_required,
                  client_app: get_client_app,
                  success: lambda do
                    clear_pre_auth_state
                    if current_user.student? || current_user.created_from_signed_data?
                      redirect_back
                    else
                      # The old instructor "access pending" review queue is retired;
                      # send instructors into the newflow educator signup/verification flow.
                      redirect_to educator_signup_path
                    end
                  end,
                  failure: lambda do
                    render 'legacy/signup/profile'
                  end)
    else
      params[:profile] = {
        school: current_user.self_reported_school
      }
      render 'legacy/signup/profile'
    end
  end

  protected

  def check_ready_for_profile
    # Only expect signed in, needs_profile users, who have a verified email
    fail_signup if !signed_in? ||
                  !current_user.is_needs_profile? ||
                  current_user.contact_infos.verified.none?

    if last_login_is_older_than?(PROFILE_TIMEOUT)
      sign_out!
      redirect_to root_path, alert: t(:"legacy.signup.profile.timeout")
    end

    true
  end

  def fail_signup
    clear_pre_auth_state
    raise SecurityTransgression
  end

  def instructor_has_selected_subject(key)
    params[:profile] && params[:profile][:subjects] && params[:profile][:subjects][key] == '1'
  end

end
