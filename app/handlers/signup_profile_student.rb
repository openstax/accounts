class SignupProfileStudent < SignupProfile

  paramify :profile do
    SignupProfile.include_common_params_in(self)
  end

  def push_lead
    true
  end

end
