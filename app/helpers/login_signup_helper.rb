module LoginSignupHelper

  BRI_BOOK_PARAM_NAME = :bri_book

  # save (in the session) or clear the client_app that sent the user here
  def cache_client_app
    set_client_app(params[:client_id])
  end

  def cache_BRI_marketing_if_present
    params[BRI_BOOK_PARAM_NAME].present? ? cache_BRI_marketing : clear_cache_BRI_marketing
  end

  def cache_BRI_marketing
    session[BRI_BOOK_PARAM_NAME] = true
  end

  def clear_cache_BRI_marketing
    session[BRI_BOOK_PARAM_NAME] = nil
  end

  def is_BRI_book_adopter?
    session[BRI_BOOK_PARAM_NAME] == true
  end

  def should_show_school_name_field?
    params[:school].present? || current_user&.is_sheerid_unviable? || current_user&.rejected_faculty? || is_cs_form?
  end

  def should_show_school_issued_email_field?
    is_cs_form?
  end

  def is_cs_form?
    request.original_fullpath.include? 'cs_form'
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
      redirect_to(signup_student_path(request.query_parameters))
    elsif known_signup_role && known_signup_role == 'instructor'
      redirect_to(instructor_signup_path(request.query_parameters))
    end
  end

end
