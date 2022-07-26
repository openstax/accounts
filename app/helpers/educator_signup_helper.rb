module EducatorSignupHelper
  def is_cs_form?
    request.original_fullpath.include? 'cs_form'
  end
end
