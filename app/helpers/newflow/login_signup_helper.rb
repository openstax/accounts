module Newflow
  module LoginSignupHelper

    # save (in the seession) or clear the client_app that sent the user here
    def cache_client_app
      set_client_app(params[:client_id])
    end

    def should_show_school_name_field?
      params[:school].present? || current_user&.is_sheerid_unviable? || current_user&.rejected_faculty?
    end

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

    def cache_redirect_uri_if_tutor
      uri = params[:redirect_uri]
      app_id = params[:client_id]

      return if app_id.blank? || uri.blank?

      client_app = Doorkeeper::Application.find_by(uid: app_id)

      if client_app&.name&.downcase&.include?('tutor') && client_app&.is_redirect_url?(URI.decode(uri))
        store_url(url: uri)
      end
    end

  end
end
