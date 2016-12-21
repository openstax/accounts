class SignupProfileOther < SignupProfile

  paramify :profile do
    SignupProfile.include_common_params_in(self)

    # These fields from SignupProfile are required for other roles:

    validates :phone_number, presence: true
    validates :url, presence: true
  end

  def push_lead
    true
  end

end
