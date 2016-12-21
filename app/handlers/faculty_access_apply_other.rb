class FacultyAccessApplyOther < FacultyAccessApply

  paramify :apply do
    FacultyAccessApply.include_common_params_in(self)
  end

end
