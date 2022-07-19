module LoginSignupHelper

  BRI_BOOK_PARAM_NAME = :bri_book

  # save (in the session) or clear the client_app that sent the user here
  def cache_client_app
    set_client_app(params[:client_id])
  end

  def cache_bri_marketing_if_present
    params[BRI_BOOK_PARAM_NAME].present? ? cache_bri_marketing : clear_cache_bri_marketing
  end

  def cache_bri_marketing
    session[BRI_BOOK_PARAM_NAME] = true
  end

  def clear_cache_bri_marketing
    session[BRI_BOOK_PARAM_NAME] = nil
  end

  def is_bri_book_adopter?
    session[BRI_BOOK_PARAM_NAME] == true
  end

  def should_show_school_name_field?
    params[:country].present? || params[:school].present? ||
      current_user&.is_sheerid_unviable? || is_cs_form?
  end

  def is_cs_form?
    request.original_fullpath.include? 'cs_form'
  end
end
