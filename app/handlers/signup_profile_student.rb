class SignupProfileStudent < SignupProfile

  paramify :profile do
    SignupProfile.include_common_params_in(self)
  end

end
