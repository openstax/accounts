module Newflow
  module LoginSignupHelper
    def generate_sheer_id_url(user:)
      url = standard_parse_url(Settings::Db.store.sheer_id_base_url)
      url.query_values = url.query_values.merge(
        first_name: user.first_name,
        last_name: user.last_name,
        email: user.email_addresses.first&.value
      )
      url.to_s
    end

    # Standardize how we parse URLs
    def standard_parse_url(url)
      Addressable::URI.parse(url)
    end

    def known_signup_role_redirect
      known_role = session.fetch(:signup_role, nil)

      if known_role && known_role == 'student'
        # TODO: when we create the Educator flow, redirect to there.
        redirect_to newflow_signup_student_path(request.query_parameters)
      end
    end

    def restart_signup_if_missing_unverified_user
      redirect_to newflow_signup_path unless unverified_user.present?
    end

    def save_unverified_user(user)
      session[:unverified_user_id] = user.id
    end

    def unverified_user
      id = session[:unverified_user_id]&.to_i
      return unless id.present?

      @unverified_user ||= User.find_by(id: id, state: 'unverified')
    end

    def clear_unverified_user
      session.delete(:unverified_user_id)
    end

    def clear_login_failed_email
      session.delete(:login_failed_email)
    end

    def clear_newflow_state
      clear_login_failed_email
      clear_unverified_user
    end

    def save_login_failed_email(email)
      session[:login_failed_email] = email
    end

    def login_failed_email
      session.delete(:login_failed_email)
    end
  end
end
