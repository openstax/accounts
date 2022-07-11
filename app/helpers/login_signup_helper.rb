module LoginSignupHelper

  # save (in the session) or clear the client_app that sent the user here
  def cache_client_app
    set_client_app(params[:client_id])
  end

  def cache_BRI_marketing_if_present
    params[:bri_book].present? ? session[:bri_book] = true : session[:bri_book] = nil
  end

  def is_BRI_book_adopter?
    session[:bri_book] == true
  end

  def should_show_school_name_field?
    params[:country].present? || params[:school].present? || current_user&.is_sheerid_unviable? || is_cs_form?
  end

  def is_cs_form?
    request.original_fullpath.include? 'cs_form'
  end
end
