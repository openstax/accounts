class SignupProfileOther < SignupProfile

  paramify :profile do
    SignupProfile.include_common_params_in(self)

    # These fields from SignupProfile are required for other roles:

    validates :phone_number, presence: true
    validates :url, presence: true
    validate :subjects, lambda { |profile|
      unless profile.subjects.detect{|_, checked| checked == '1'}
        profile.errors.add(:subjects, 'must have at least one selection')
      end
    }
  end

  def push_lead
    true
  end

end
