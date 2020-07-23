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
      known_signup_role = session.fetch(:signup_role, nil)

      if known_signup_role && known_signup_role == 'student'
        redirect_to(newflow_signup_student_path(request.query_parameters))
      elsif known_signup_role && known_signup_role == 'instructor'
        redirect_to(educator_signup_path(request.query_parameters))
      end
    end

  end
end
