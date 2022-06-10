module EducatorSignupHelper
  def is_cs_form?
    request.original_fullpath.include? 'cs_form'
  end

  #TODO: why?
  def user
    current_user
  end

  def is_BRI_book_adopter?
    session[:bri_book] == true
  end

  def should_show_school_name_field?
    params[:country].present? || params[:school].present? || current_user&.is_sheerid_unviable? || is_cs_form?
  end
end
