module EducatorSignupHelper
  def sheerid_provided_verification_id_param
    params[:verificationid]
  end

  def is_cs_form?
    request.original_fullpath.include? 'cs_form'
  end
end
