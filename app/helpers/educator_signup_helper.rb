module EducatorSignupHelper
  def sheerid_provided_verification_id_param
    params[:verificationid]
  end

  def should_show_school_issued_email_field?
    is_cs_form?
  end

  def is_cs_form?
    request.original_fullpath.include? 'cs_form'
  end

  def user
    current_user
  end

end
